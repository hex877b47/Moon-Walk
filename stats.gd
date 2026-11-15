extends Node
## Autoload "Stats": medidores, módulos, fallas, EVA y balance.
## Todos los valores de BALANCE son "por día de juego". 1 día = 10 min reales,
## así que (valor por día) / 10 = valor por minuto real.

signal stat_changed(stat_name: String, value: float, max_value: float)
signal module_changed(module_name: String, working: bool)
signal flare_happened(in_shelter: bool)
signal player_died(reason: String)
signal game_won(day: int, science: int)
signal eva_changed(active: bool)
signal science_changed(points: int)
signal harvest_ready_changed(is_ready: bool)

const MAX_VALUE := 100.0
const MINUTES_PER_DAY := 1440.0
const GOAL_DAY := 7    # se gana al empezar el día 7 (≈ 58 min reales)

# ---------- BALANCE (por día de juego) ----------
const BASE_DRAIN := {          # -4 / -2.5 / -2 / -2 por minuto real
	"oxygen": 40.0,
	"water": 25.0,
	"food": 20.0,
	"energy": 20.0,
}
const PRODUCTION := {          # módulo funcionando (energía: solo de día)
	"oxygen": 60.0,
	"water": 40.0,
	"energy": 50.0,
}
const O2_GENERATOR_ENERGY_COST := 20.0
const GREENHOUSE_GROW_MINUTES := 432.0   # minutos de JUEGO (≈ 3 min reales)
const HARVEST_FOOD := 12.0               # el plan decía 25; ver CAMBIOS.md

const FLARE_RADIATION_NO_SHELTER := 30.0
const FLARE_RADIATION_SHELTER := 5.0
const SHELTER_RADIATION_RECOVERY := 30.0  # -3 por minuto real dentro del refugio

const HEALTH_LOSS_WATER_ZERO := 60.0
const HEALTH_LOSS_FOOD_ZERO := 25.0

const EVA_MIN := {"oxygen": 15.0, "energy": 10.0}   # mínimo para poder salir
const EVA_O2_EXTRA := 80.0                # -8 O2 extra por minuto real
const EVA_RADIATION_PER_DAY := 60.0       # una EVA de ~3 min reales = +18

const MODULE_NAMES := {
	"oxygen_generator": "Generador de O2",
	"water_recycler": "Reciclador de agua",
	"greenhouse": "Invernadero",
	"solar_panels": "Paneles solares",
}

# ---------- ESTADO ----------
var values := {
	"oxygen": 80.0,
	"water": 80.0,
	"food": 80.0,
	"energy": 80.0,
	"radiation": 10.0,
	"health": 100.0,
}

# true = el módulo existe / está construido
var modules := {
	"oxygen_generator": true,
	"water_recycler": true,
	"greenhouse": true,
	"solar_panels": true,
}

var broken := {}                 # módulo -> true si está averiado
var greenhouse_progress := 0.0   # minutos de juego de crecimiento
var solar_multiplier := 1.0      # tormenta de polvo lo baja
var science := 0
var in_shelter := false
var in_eva := false
var is_dead := false
var won := false

var _last_working := {}

var harvest_ready: bool:
	get:
		return greenhouse_progress >= GREENHOUSE_GROW_MINUTES


func _ready() -> void:
	TimeManager.minute_changed.connect(_on_minute)
	TimeManager.day_changed.connect(_on_day_changed)


## Multiplicador de dificultad del plan: 1 + 0.15 x día. Afecta a eventos, no al consumo.
func difficulty() -> float:
	return 1.0 + 0.15 * TimeManager.day


# ---------- TICK POR MINUTO DE JUEGO ----------
func _on_minute(_hour: int, _minute: int) -> void:
	if is_dead or won:
		return

	var per_min := 1.0 / MINUTES_PER_DAY

	for s in BASE_DRAIN:
		change(s, -BASE_DRAIN[s] * per_min)

	if _is_working("oxygen_generator"):
		change("oxygen", PRODUCTION["oxygen"] * per_min)
		change("energy", -O2_GENERATOR_ENERGY_COST * per_min)
	if _is_working("water_recycler"):
		change("water", PRODUCTION["water"] * per_min)

	if _is_working("greenhouse") and not harvest_ready:
		greenhouse_progress += 1.0
		if harvest_ready:
			harvest_ready_changed.emit(true)

	# Solar: no necesita energía, solo luz
	if _is_working("solar_panels", false) and TimeManager.is_daylight():
		var sun_minutes := float((TimeManager.SUNSET_HOUR - TimeManager.SUNRISE_HOUR) * 60)
		change("energy", PRODUCTION["energy"] * solar_multiplier / sun_minutes)

	if in_shelter:
		change("radiation", -SHELTER_RADIATION_RECOVERY * per_min)

	if in_eva:
		change("oxygen", -EVA_O2_EXTRA * per_min)
		change("radiation", EVA_RADIATION_PER_DAY * per_min)

	if values["water"] <= 0.0:
		change("health", -HEALTH_LOSS_WATER_ZERO * per_min)
	if values["food"] <= 0.0:
		change("health", -HEALTH_LOSS_FOOD_ZERO * per_min)

	_update_modules_power_state()


func _on_day_changed(d: int) -> void:
	if d >= GOAL_DAY and not won and not is_dead:
		won = true
		game_won.emit(d, science)


# ---------- EVENTOS ----------
func trigger_flare() -> void:
	if is_dead or won:
		return
	flare_happened.emit(in_shelter)
	var gain: float = FLARE_RADIATION_SHELTER if in_shelter else FLARE_RADIATION_NO_SHELTER
	gain *= difficulty()
	change("radiation", gain)
	var suffix := " (protegido)" if in_shelter else ""
	EventBus.message.emit("Llamarada solar: radiación +%d%s" % [int(gain), suffix])


func break_module(m: String) -> void:
	if not modules.get(m, false):
		return
	broken[m] = true
	_update_modules_power_state()


func repair_module(m: String) -> void:
	if not is_broken(m):
		return
	broken[m] = false
	add_science(1)
	EventBus.message.emit("%s reparado." % MODULE_NAMES.get(m, m))
	_update_modules_power_state()


func is_broken(m: String) -> bool:
	return bool(broken.get(m, false))


# ---------- ACCIONES ----------
func begin_eva() -> bool:
	if in_eva:
		return true
	if values["oxygen"] < EVA_MIN["oxygen"] or values["energy"] < EVA_MIN["energy"]:
		return false
	in_eva = true
	in_shelter = false
	eva_changed.emit(true)
	return true


func end_eva() -> void:
	if not in_eva:
		return
	in_eva = false
	eva_changed.emit(false)


func harvest() -> bool:
	if not harvest_ready:
		return false
	greenhouse_progress = 0.0
	change("food", HARVEST_FOOD)
	harvest_ready_changed.emit(false)
	return true


func eat_ration(amount: float = 20.0) -> void:
	change("food", amount)


func set_shelter(value: bool) -> void:
	in_shelter = value


func add_science(points: int) -> void:
	science += points
	science_changed.emit(science)


# ---------- NÚCLEO ----------
func change(stat: String, amount: float) -> void:
	if is_dead:
		return
	var new_value: float = values[stat] + amount

	# Radiación: muerte si pasa de 100
	if stat == "radiation" and new_value > MAX_VALUE:
		values[stat] = MAX_VALUE
		stat_changed.emit(stat, MAX_VALUE, MAX_VALUE)
		_die("Radiación letal")
		return

	values[stat] = clampf(new_value, 0.0, MAX_VALUE)
	stat_changed.emit(stat, values[stat], MAX_VALUE)

	if stat == "oxygen" and values[stat] <= 0.0:
		_die("Sin oxígeno")
	elif stat == "health" and values[stat] <= 0.0:
		_die("Salud agotada")


func _is_working(m: String, needs_power: bool = true) -> bool:
	if not modules.get(m, false) or is_broken(m):
		return false
	return (not needs_power) or values["energy"] > 0.0


func _update_modules_power_state() -> void:
	for m in modules:
		var w := _is_working(m, m != "solar_panels")
		if _last_working.get(m) != w:
			_last_working[m] = w
			module_changed.emit(m, w)


func _die(reason: String) -> void:
	is_dead = true
	player_died.emit(reason)
	print("MUERTE: ", reason)


func reset() -> void:
	values = {"oxygen": 80.0, "water": 80.0, "food": 80.0,
		"energy": 80.0, "radiation": 10.0, "health": 100.0}
	broken.clear()
	_last_working.clear()
	greenhouse_progress = 0.0
	solar_multiplier = 1.0
	science = 0
	is_dead = false
	won = false
	in_shelter = false
	in_eva = false
	TimeManager.reset()
	EventDirector.reset()
	for s in values:
		stat_changed.emit(s, values[s], MAX_VALUE)
