extends Node
## Autoload "TimeManager": reloj del juego. 1 día = day_length_seconds reales (600 = 10 min).
## Día: 06:00 a 23:00 hay luz (17 h ≈ 7 min reales); 23:00 a 06:00 es noche (≈ 3 min).

signal minute_changed(hour: int, minute: int)
signal day_changed(day: int)

const MINUTES_PER_DAY := 24 * 60
const SUNRISE_HOUR := 6
const SUNSET_HOUR := 23

@export var day_length_seconds: float = 600.0

var time_scale: float = 1.0      # depuración: F4 en el HUD cicla x1 / x5 / x10
var day: int = 1
var paused: bool = false

var _minute: int = 6 * 60        # minuto del día (empieza a las 6:00)
var _frac: float = 0.0

var time_of_day: float:
	get:
		return float(_minute) + _frac


func _process(delta: float) -> void:
	if paused:
		return
	_frac += minf(delta, 0.25) * time_scale * (MINUTES_PER_DAY / day_length_seconds)
	while _frac >= 1.0:
		_frac -= 1.0
		_step_minute()


func _step_minute() -> void:
	_minute += 1
	if _minute >= MINUTES_PER_DAY:
		_minute = 0
		day += 1
		day_changed.emit(day)
	minute_changed.emit(get_hour(), get_minute())


func get_hour() -> int:
	return floori(_minute / 60.0)

func get_minute() -> int:
	return _minute % 60

func get_time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]

func is_daylight() -> bool:
	var h := get_hour()
	return h >= SUNRISE_HOUR and h < SUNSET_HOUR

## Minutos de juego acumulados desde el inicio (sirve para programar eventos).
func total_minutes() -> float:
	return float((day - 1) * MINUTES_PER_DAY + _minute) + _frac

## Alias que usa solar_flare.gd (versión del compañero).
func get_total_minutes() -> float:
	return total_minutes()

## Convierte segundos reales (a velocidad x1) en minutos de juego.
func real_second_to_game_minutes(seconds: float) -> float:
	return seconds * (MINUTES_PER_DAY / day_length_seconds)

func skip_to_next_day(start_hour: int = 6) -> void:
	day += 1
	_minute = start_hour * 60
	_frac = 0.0
	day_changed.emit(day)

func reset() -> void:
	day = 1
	_minute = 6 * 60
	_frac = 0.0
	time_scale = 1.0
	paused = false
