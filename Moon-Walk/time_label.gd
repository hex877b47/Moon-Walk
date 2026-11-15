extends Label

func _ready() -> void:
	TimeManager.minute_changed.connect(_actualizar)
	_actualizar()

func _actualizar(_h = 0, _m = 0) -> void:
	text = "Día %d - %s" % [TimeManager.day, TimeManager.get_time_string()]
