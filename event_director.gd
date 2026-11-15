extends Node
## Autoload "EventDirector": programa eventos. Hitos fijos (día 2, 4, 6) + aleatorios.
## Todo se mide en tiempo de JUEGO, así que la tecla de acelerar tiempo también acelera los eventos.

const EVENT_HOUR := 8                  # cada día planifica a las 08:00
const FLARE_WARNING_SECONDS := 20.0    # segundos reales entre aviso e impacto
const RANDOM_FLARE_CHANCE := 0.5       # ≈ 1 llamarada cada 2 días
const STORM_DURATION_SECONDS := 150.0

var _scheduled: Array[Dictionary] = []
var _planned_day := 0


func _ready() -> void:
	TimeManager.minute_changed.connect(_on_minute)


func reset() -> void:
	_scheduled.clear()
	_planned_day = 0


## Ejecuta `action` dentro de `seconds_real` segundos reales (a velocidad x1).
func schedule(seconds_real: float, action: Callable) -> void:
	var minutes := seconds_real * TimeManager.MINUTES_PER_DAY / TimeManager.day_length_seconds
	_scheduled.append({"at": TimeManager.total_minutes() + minutes, "do": action})


func _on_minute(hour: int, _minute: int) -> void:
	if Stats.is_dead or Stats.won:
		return
	var now := TimeManager.total_minutes()
	for e in _scheduled.duplicate():
		if now >= e["at"]:
			_scheduled.erase(e)
			e["do"].call()
	if hour >= EVENT_HOUR and TimeManager.day > _planned_day:
		_planned_day = TimeManager.day
		_plan_day(TimeManager.day)


func _plan_day(d: int) -> void:
	match d:
		1:
			pass   # día de gracia: aprender los controles
		2:
			_flare(true)                     # hito: primera llamarada con tutorial
		4:
			break_random(2)                  # hito: falla doble
		6:
			_dust_storm()                    # hito: tormenta de polvo
			break_random(1)
		_:
			var failures := 1
			if randf() < (Stats.difficulty() - 1.0) * 0.5:
				failures += 1
			break_random(failures)
			if randf() < RANDOM_FLARE_CHANCE:
				schedule(randf_range(30.0, 240.0), _flare)


func _flare(tutorial: bool = false) -> void:
	var text := "¡Llamarada solar en %d s! Corre al refugio." % int(FLARE_WARNING_SECONDS)
	if tutorial:
		text += " Si la radiación llega a 100, mueres."
	EventBus.message.emit(text)
	EventBus.flare_warning.emit(FLARE_WARNING_SECONDS)
	schedule(FLARE_WARNING_SECONDS, Stats.trigger_flare)


func break_random(count: int = 1) -> void:
	var candidates: Array = []
	for m in Stats.modules:
		if Stats.modules[m] and not Stats.is_broken(m):
			candidates.append(m)
	candidates.shuffle()
	for i in mini(count, candidates.size()):
		var m: String = candidates[i]
		Stats.break_module(m)
		EventBus.message.emit("¡Falla en %s! Mantén [E] en la estación para repararla." % Stats.MODULE_NAMES.get(m, m))


func _dust_storm() -> void:
	Stats.solar_multiplier = 0.25
	EventBus.message.emit("Tormenta de polvo: los paneles rinden al 25 %.")
	schedule(STORM_DURATION_SECONDS, _end_storm)


func _end_storm() -> void:
	Stats.solar_multiplier = 1.0
	EventBus.message.emit("La tormenta de polvo terminó.")
