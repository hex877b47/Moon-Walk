extends Node

signal stat_changed(stat_name: String, value: float, max_value: float)
signal module_changed(module_name: String, working: bool)
signal flare_happened(in_shelter: bool)
signal player_died(reason: String)

const MAX_VALUE := 100.0
const MINUTES_PER_DAY := 1440.0

const FLARE_SCENE := preload("res://solar_wave.tscn")
var flare_pool: Array[FlareData] = []
var _flare_active := false


# ---------- BALANCE (por día, ajustable) ----------
const BASE_DRAIN := {          # consumo base
	"oxygen": 10.0,
	"water": 8.0,
	"food": 8.0,
	"energy": 15.0,
}
const PRODUCTION := {          # producción con módulo funcionando
	"oxygen": 14.0,            # generador de O2
	"water": 10.0,             # reciclador
	"food": 9.0,               # invernadero
	"energy": 20.0,            # paneles solares (solo de día)
}
const O2_GENERATOR_ENERGY_COST := 6.0
const SOLAR_START_HOUR := 6
const SOLAR_END_HOUR := 18

const FLARE_RADIATION_NO_SHELTER := 35.0
const FLARE_RADIATION_SHELTER := 5.0
const FLARE_CHANCE_PER_DAY := 0.25
const SHELTER_RADIATION_RECOVERY := 6.0   # por día dentro del refugio

const HEALTH_LOSS_WATER_ZERO := 8.0       # por día (rápido)
const HEALTH_LOSS_FOOD_ZERO := 3.0        # por día (lento)

const EVA_COST := {"oxygen": 15.0, "energy": 10.0}
const EVA_RADIATION_MIN := 10.0
const EVA_RADIATION_MAX := 30.0

# ---------- ESTADO ----------
var values := {
	"oxygen": 80.0,
	"water": 80.0,
	"food": 80.0,
	"energy": 80.0,
	"radiation": 10.0,
	"health": 100.0,
}

# módulos construidos (true = existe). Actívalos según avance el juego
var modules := {
	"oxygen_generator": true,
	"water_recycler": true,
	"greenhouse": true,
	"solar_panels": true,
}

var in_shelter := false
var is_dead := false


func _ready() -> void:
	TimeManager.minute_changed.connect(_on_minute)
	TimeManager.day_changed.connect(_on_day_changed)
	_load_flares()


# ---------- TICK POR MINUTO DE JUEGO ----------
func _on_minute(hour: int, _minute: int) -> void:
	if is_dead:
		return

	var per_min := 1.0 / MINUTES_PER_DAY

	# Consumo base
	for s in BASE_DRAIN:
		change(s, -BASE_DRAIN[s] * per_min)

	# Producción (solo funciona si hay energía)
	var has_power: bool = values["energy"] > 0.0

	if modules["oxygen_generator"] and has_power:
		change("oxygen", PRODUCTION["oxygen"] * per_min)
		change("energy", -O2_GENERATOR_ENERGY_COST * per_min)
	if modules["water_recycler"] and has_power:
		change("water", PRODUCTION["water"] * per_min)
	if modules["greenhouse"] and has_power:
		change("food", PRODUCTION["food"] * per_min)

	# Solar: solo de día. +20 por día repartido en las horas de sol
	if modules["solar_panels"] and hour >= SOLAR_START_HOUR and hour < SOLAR_END_HOUR:
		var sun_minutes := float((SOLAR_END_HOUR - SOLAR_START_HOUR) * 60)
		change("energy", PRODUCTION["energy"] / sun_minutes)

	# Radiación baja en el refugio
	if in_shelter:
		change("radiation", -SHELTER_RADIATION_RECOVERY * per_min)

	# Efectos de llegar a 0
	if values["water"] <= 0.0:
		change("health", -HEALTH_LOSS_WATER_ZERO * per_min)
	if values["food"] <= 0.0:
		change("health", -HEALTH_LOSS_FOOD_ZERO * per_min)

	_update_modules_power_state()


# ---------- TICK POR DÍA ----------
func _on_day_changed(_day: int) -> void:
	if randf() < FLARE_CHANCE_PER_DAY:
		spawn_flare_event()

func _load_flares() -> void:
	var file := FileAccess.open("res://data/flares.json", FileAccess.READ)
	if file == null:
		push_error("No se encontró res://data/flares.json")
		return
	var raw = JSON.parse_string(file.get_as_text())
	if raw == null:
		push_error("flares.json tiene un error de formato")
		return
	for d in raw:
		flare_pool.append(FlareData.from_donki(d))
	print("Llamaradas cargadas: ", flare_pool.size())
	
func spawn_flare_event() -> void:
	if _flare_active or flare_pool.is_empty():
		return
	_flare_active = true
	var f: FlareData = flare_pool.pick_random()
	var ev := FLARE_SCENE.instantiate() as SolarFlareEvent
	get_tree().current_scene.add_child(ev)
	ev.setup(f.game_warning_minutes())
	ev.duration_minutes = f.game_duration_minutes()
	ev.impact_started.connect(trigger_flare.bind(f.damage_multiplier()))
	ev.finished.connect(func(): _flare_active = false)
	print("Llamarada ", f.class_label, " del ", f.real_date)
	ev.impact_started.connect(func(): Messages.show_from(f))

func trigger_flare(mult: float = 1.0) -> void:
	flare_happened.emit(in_shelter)
	var base := FLARE_RADIATION_SHELTER if in_shelter else FLARE_RADIATION_NO_SHELTER
	change("radiation", base * mult)

# ---------- ACCIONES ----------
func start_eva(radiation_gain: float = 20.0) -> bool:
	# radiation_gain según el destino (entre 10 y 30)
	if values["oxygen"] < EVA_COST["oxygen"] or values["energy"] < EVA_COST["energy"]:
		return false  # no alcanza para salir
	change("oxygen", -EVA_COST["oxygen"])
	change("energy", -EVA_COST["energy"])
	change("radiation", clampf(radiation_gain, EVA_RADIATION_MIN, EVA_RADIATION_MAX))
	return true


func eat_ration(amount: float = 20.0) -> void:
	change("food", amount)


func set_shelter(value: bool) -> void:
	in_shelter = value


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


func _update_modules_power_state() -> void:
	var working: bool = values["energy"] > 0.0
	for m in modules:
		module_changed.emit(m, modules[m] and working)


func _die(reason: String) -> void:
	is_dead = true
	player_died.emit(reason)
	print("MUERTE: ", reason)


func reset() -> void:
	values = {"oxygen": 80.0, "water": 80.0, "food": 80.0,
		"energy": 80.0, "radiation": 10.0, "health": 100.0}
	is_dead = false
	in_shelter = false
