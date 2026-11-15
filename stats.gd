extends Node
## Autoload "Stats": medidores, módulos, fallas, EVA y balance.
## Todos los valores de BALANCE son "por día de juego". 1 día = 10 min reales,
## así que (valor por día) / 10 = valor por minuto real.
##
## Versión "realista": radiación como dosis acumulada (mSv), consumo derivado de
## kg/día reales, caminata que gasta energía por distancia, y medidores que
## afectan velocidad, esfuerzo y salud.

signal stat_changed(stat_name: String, value: float, max_value: float)
signal module_changed(module_name: String, working: bool)
signal flare_happened(in_shelter: bool)
signal flare_ended
signal player_died(reason: String)
signal game_won(day: int, science: int)
signal eva_changed(active: bool)
signal science_changed(points: int)
signal harvest_ready_changed(is_ready: bool)

const MAX_VALUE := 100.0
const MINUTES_PER_DAY := 1440.0
const GOAL_DAY := 7    # se gana al empezar el día 7 (≈ 58 min reales)

# =====================================================
# CONSUMO BASE (por día de juego, en reposo)
# Derivado de necesidades humanas reales x TIME_COMPRESSION (=4, partida de 7 días):
#   O2    0.84 kg/día  de un depósito de 8.4 kg -> 10 %/día x 4 = 40
#   agua  3.0 L/día    de 48 L                  -> 6.25 %/día x 4 = 25
#   comida 0.8 kg/día  de 16 kg                 -> 5 %/día x 4 = 20
# =====================================================
const BASE_DRAIN := {
	"oxygen": 40.0,
	"water": 25.0,
	"food": 20.0,
	"energy": 20.0,
}
# Producción de la ESTACIÓN: el generador y el reciclador solo reponen al astronauta
# mientras está DENTRO de la base (no en EVA). Los paneles solares no dan energía al
# astronauta: alimentan la estación (si se averían o hay tormenta, la base produce menos).
const PRODUCTION := {
	"oxygen": 60.0,    # generador de O2 (dentro de la base)
	"water": 40.0,     # reciclador de agua (dentro de la base)
}
# "energy" es el DESCANSO del astronauta (100 % = sin cansancio).
# Baja con el tiempo y al caminar; se recupera descansando quieto dentro de la base.
const ENERGY_REST_RECOVERY_PER_DAY := 90.0
const GREENHOUSE_GROW_MINUTES := 432.0   # minutos de JUEGO (≈ 3 min reales)
const HARVEST_FOOD := 12.0               # el plan decía 25; ver CAMBIOS.md

# =====================================================
# RADIACIÓN
# El medidor (0-100) = dosis acumulada / dosis letal.
# Tasas en mSv/hora (equivalente de dosis). Superficie lunar ≈ 57 µSv/h
# (NASA RadLab: celestial_body=Moon, campo dose_equivalent_rate).
# =====================================================
const LETHAL_DOSE_MSV := 4000.0          # ≈ LD50/60 sin tratamiento (4 Sv)
const SICKNESS_DOSE_MSV := 2000.0        # medidor en 50 %: la radiación empieza a debilitarte
const START_RADIATION := 10.0            # medidor inicial (%)

const DOSE_RATE_OUTSIDE_MSV_H := 0.0574  # EVA en superficie
# Fracción de la dosis de superficie que llega según dónde estés
const BACKGROUND_SHIELDING := {"outside": 1.0, "habitat": 0.05, "shelter": 0.01}
# Compresión de tiempo: 1740 hace que una EVA = +60 %/día (como tu plan original)
const BACKGROUND_GAME_SCALE := 1740.0

# Llamarada solar (evento de protones): dura horas, no es instantánea.
# ≈ 60 mSv totales sin blindaje (10 mSv/h x 6 h) x FLARE_GAME_SCALE 20 = +30 % del medidor
const FLARE_RATE_MSV_H := 10.0
const FLARE_DURATION_H := 6.0
const FLARE_GAME_SCALE := 20.0
const FLARE_SHIELDING := {"outside": 1.0, "habitat": 0.5, "shelter": 0.15}

const SHELTER_RECOVERY_MSV_DAY := 1200.0  # = -30 %/día en refugio (simplificación de juego)

# =====================================================
# SALUD (puntos de salud por día de juego)
# =====================================================
const HEALTH_LOSS_WATER_ZERO := 60.0
const HEALTH_LOSS_FOOD_ZERO := 25.0
const HEALTH_LOSS_OXYGEN_ZERO := 720.0   # hipoxia: ~3 h de juego (≈ 80 s reales)
const HEALTH_LOSS_RADIATION_MAX := 60.0  # a radiación 100 %
# La radiación te debilita pero NO te mata por salud: solo mata al llegar a 100 %.
const RADIATION_HEALTH_FLOOR := 25.0
const HEALTH_REGEN_PER_DAY := 20.0       # solo si O2, agua y comida > 20 y sin síndrome

# =====================================================
# EVA y CAMINATA
# =====================================================
const EVA_MIN := {"oxygen": 15.0, "energy": 10.0}   # mínimo para poder salir
const EVA_O2_EXTRA := 80.0                # -8 O2 extra por minuto real (traje)

# Gasto por metro caminado (en % del medidor). 1 km = 30 % de energía.
const ENERGY_PER_METER := 0.03
const WALK_EXTRA_PER_METER := {
	"oxygen": 0.02,    # 100 m = 2 % O2
	"water": 0.015,    # 100 m = 1.5 % agua
	"food": 0.006,     # 100 m = 0.6 % comida
}

const MIN_SPEED_MULT := 0.15

const FLARE_WARNING := "¡La llamarada solar ya llegó! Entra al refugio."

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
	"radiation": START_RADIATION,
	"health": 100.0,
}
var dose_msv := START_RADIATION / 100.0 * LETHAL_DOSE_MSV

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
var flare_hours_left := 0.0
var walked_total_m := 0.0
var _walked_recently := false

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

	var power := station_power()

	# Soporte vital de la base: solo funciona si el astronauta está dentro
	if not in_eva:
		if _is_working("oxygen_generator"):
			change("oxygen", PRODUCTION["oxygen"] * power * per_min)
		if _is_working("water_recycler"):
			change("water", PRODUCTION["water"] * power * per_min)
		# Descanso: quieto dentro de la base se recupera el cansancio
		if not _walked_recently:
			change("energy", ENERGY_REST_RECOVERY_PER_DAY * per_min)
	_walked_recently = false

	if _is_working("greenhouse") and not harvest_ready:
		greenhouse_progress += 1.0
		if harvest_ready:
			harvest_ready_changed.emit(true)

	if in_eva:
		change("oxygen", -EVA_O2_EXTRA * per_min)

	_tick_radiation(per_min)
	_tick_health(per_min)

	_update_modules_power_state()


func _on_day_changed(d: int) -> void:
	if d >= GOAL_DAY and not won and not is_dead:
		won = true
		game_won.emit(d, science)


# ---------- RADIACIÓN ----------
func get_location() -> String:
	if in_eva:
		return "outside"
	if in_shelter:
		return "shelter"
	return "habitat"


## Tasa de dosis actual en mSv/hora reales (sin escala de juego)
func get_dose_rate_msv_h() -> float:
	var loc := get_location()
	var rate: float = DOSE_RATE_OUTSIDE_MSV_H * BACKGROUND_SHIELDING[loc]
	if flare_hours_left > 0.0:
		rate += FLARE_RATE_MSV_H * FLARE_SHIELDING[loc] * difficulty()
	return rate


func _tick_radiation(per_min: float) -> void:
	var loc := get_location()
	var per_hour := 1.0 / 60.0

	# Fondo (rayos cósmicos + viento solar), comprimido al tiempo de juego
	var dose: float = DOSE_RATE_OUTSIDE_MSV_H * BACKGROUND_SHIELDING[loc] \
		* BACKGROUND_GAME_SCALE * per_hour

	# Llamarada en curso
	if flare_hours_left > 0.0:
		dose += FLARE_RATE_MSV_H * FLARE_SHIELDING[loc] * difficulty() \
			* FLARE_GAME_SCALE * per_hour
		flare_hours_left -= per_hour
		if flare_hours_left <= 0.0:
			flare_hours_left = 0.0
			flare_ended.emit()
			EventBus.message.emit("La llamarada solar terminó.")

	# Reparación biológica en refugio
	if in_shelter and not in_eva:
		dose -= SHELTER_RECOVERY_MSV_DAY * per_min

	_add_dose(dose)


## 0 = sin efectos (radiación <= 50 %), 1 = efectos máximos (radiación en 100 %)
func radiation_sickness() -> float:
	return clampf((dose_msv - SICKNESS_DOSE_MSV) / (LETHAL_DOSE_MSV - SICKNESS_DOSE_MSV), 0.0, 1.0)


func _add_dose(msv: float) -> void:
	if is_dead:
		return
	dose_msv = maxf(dose_msv + msv, 0.0)
	values["radiation"] = clampf(dose_msv / LETHAL_DOSE_MSV * MAX_VALUE, 0.0, MAX_VALUE)
	stat_changed.emit("radiation", values["radiation"], MAX_VALUE)
	if dose_msv >= LETHAL_DOSE_MSV:
		_die("Radiación letal")


# ---------- SALUD ----------
func _tick_health(per_min: float) -> void:
	var loss := 0.0
	if values["oxygen"] <= 0.0:
		loss += HEALTH_LOSS_OXYGEN_ZERO * per_min
	if values["water"] <= 0.0:
		loss += HEALTH_LOSS_WATER_ZERO * per_min
	if values["food"] <= 0.0:
		loss += HEALTH_LOSS_FOOD_ZERO * per_min
	if values["health"] > RADIATION_HEALTH_FLOOR:
		loss += radiation_sickness() * HEALTH_LOSS_RADIATION_MAX * per_min

	if loss > 0.0:
		change("health", -loss)
	elif values["oxygen"] > 20.0 and values["water"] > 20.0 and values["food"] > 20.0 \
			and radiation_sickness() <= 0.0:
		change("health", HEALTH_REGEN_PER_DAY * per_min)


# ---------- MOVIMIENTO (llamar desde el jugador) ----------
func register_walk(meters: float) -> void:
	if is_dead or won or meters <= 0.0:
		return
	# Con el tiempo acelerado (F4) la producción y el consumo base corren x veces más
	# rápido; el costo de caminar se escala igual para que el balance no se rompa al probar.
	_walked_recently = true
	var k := maxf(TimeManager.time_scale, 1.0)
	change("energy", -ENERGY_PER_METER * meters * get_effort_multiplier() * k)
	for s in WALK_EXTRA_PER_METER:
		change(s, -WALK_EXTRA_PER_METER[s] * meters * k)
	walked_total_m += meters


## Velocidad (0.15 - 1.0) según energía, agua, comida, oxígeno, salud y radiación
func get_speed_multiplier() -> float:
	if is_dead or won:
		return 0.0
	var m := 1.0
	m *= _factor(values["energy"], 30.0, 0.5)
	m *= _factor(values["water"], 30.0, 0.6)
	m *= _factor(values["food"], 25.0, 0.7)
	m *= _factor(values["oxygen"], 35.0, 0.4)
	m *= _factor(values["health"], 60.0, 0.4)
	m *= lerpf(1.0, 0.6, radiation_sickness())
	return maxf(m, MIN_SPEED_MULT)


## Cuánto más cuesta moverse con hambre, sed, hipoxia o heridas (1.0 - ~2.3)
func get_effort_multiplier() -> float:
	var e := 1.0
	e += 1.0 - _factor(values["food"], 25.0, 0.7)
	e += 1.0 - _factor(values["water"], 30.0, 0.6)
	e += 1.0 - _factor(values["oxygen"], 35.0, 0.4)
	e += 1.0 - _factor(values["health"], 60.0, 0.4)
	return e


func _factor(value: float, threshold: float, min_factor: float) -> float:
	return lerpf(min_factor, 1.0, clampf(value / threshold, 0.0, 1.0))


# ---------- EVENTOS ----------
func trigger_flare() -> void:
	if is_dead or won:
		return
	flare_hours_left = FLARE_DURATION_H
	flare_happened.emit(in_shelter)
	EventBus.message.emit(FLARE_WARNING)


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


func drink(amount: float = 15.0) -> void:
	change("water", amount)


func set_shelter(value: bool) -> void:
	in_shelter = value


func add_science(points: int) -> void:
	science += points
	science_changed.emit(science)


# ---------- NÚCLEO ----------
func change(stat: String, amount: float) -> void:
	if is_dead:
		return

	# La radiación se maneja como dosis: amount viene en puntos del medidor
	if stat == "radiation":
		_add_dose(amount / MAX_VALUE * LETHAL_DOSE_MSV)
		return

	values[stat] = clampf(values[stat] + amount, 0.0, MAX_VALUE)
	stat_changed.emit(stat, values[stat], MAX_VALUE)

	if stat == "health" and values[stat] <= 0.0:
		_die(_death_cause())


func _death_cause() -> String:
	if values["oxygen"] <= 0.0:
		return "Sin oxígeno"
	if radiation_sickness() >= 0.5:
		return "Síndrome agudo de radiación"
	if values["water"] <= 0.0:
		return "Deshidratación"
	if values["food"] <= 0.0:
		return "Inanición"
	return "Salud agotada"


## Potencia de la estación (0-1): los paneles la alimentan; averiados = 0, tormenta = menos
func station_power() -> float:
	if not modules.get("solar_panels", false) or is_broken("solar_panels"):
		return 0.0
	return solar_multiplier


func _is_working(m: String) -> bool:
	if not modules.get(m, false) or is_broken(m):
		return false
	return m == "solar_panels" or station_power() > 0.0


func _update_modules_power_state() -> void:
	for m in modules:
		var w := _is_working(m)
		if _last_working.get(m) != w:
			_last_working[m] = w
			module_changed.emit(m, w)


func _die(reason: String) -> void:
	if is_dead:
		return
	is_dead = true
	player_died.emit(reason)
	print("MUERTE: ", reason)


func reset() -> void:
	values = {"oxygen": 80.0, "water": 80.0, "food": 80.0,
		"energy": 80.0, "radiation": START_RADIATION, "health": 100.0}
	dose_msv = START_RADIATION / 100.0 * LETHAL_DOSE_MSV
	broken.clear()
	_last_working.clear()
	greenhouse_progress = 0.0
	solar_multiplier = 1.0
	science = 0
	is_dead = false
	won = false
	in_shelter = false
	in_eva = false
	flare_hours_left = 0.0
	walked_total_m = 0.0
	_walked_recently = false
	TimeManager.reset()
	EventDirector.reset()
	for s in values:
		stat_changed.emit(s, values[s], MAX_VALUE)
