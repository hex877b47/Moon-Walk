extends Node

signal minute_changed(hour: int, minute: int)
signal day_changed(day: int)

const MINUTES_PER_DAY := 24 * 60

@export var day_length_seconds: float = 600.0  # 10 min reales = 1 día del juego

var day: int = 1
var time_of_day: float = 6.0 * 60.0  # empieza a las 6:00
var paused: bool = false
var _last_minute := -1

func _process(delta: float) -> void:
	if paused:
		return

	time_of_day += delta * (MINUTES_PER_DAY / day_length_seconds)

	if time_of_day >= MINUTES_PER_DAY:
		time_of_day -= MINUTES_PER_DAY
		day += 1
		day_changed.emit(day)

	var m := get_minute()
	if m != _last_minute:
		_last_minute = m
		minute_changed.emit(get_hour(), m)

func get_hour() -> int:
	return floori(time_of_day / 60.0)

func get_minute() -> int:
	return floori(time_of_day) % 60

func get_time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]

func skip_to_next_day(start_hour: int = 6) -> void:
	day += 1
	time_of_day = start_hour * 60.0
	day_changed.emit(day)

#Minutos totales desde el dia 1, 00:00. No se reinicia
func get_total_minutes()->float:
	return (day-1)*MINUTES_PER_DAY+time_of_day

func real_second_to_game_minutes(seconds:float)->float:
	return seconds * (MINUTES_PER_DAY/day_length_seconds)
