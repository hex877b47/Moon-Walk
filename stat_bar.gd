extends ProgressBar

@export var stat_name := "oxygen"

func _ready() -> void:
	Stats.stat_changed.connect(_on_stat_changed)
	max_value = Stats.MAX_VALUE
	value = Stats.values[stat_name]

func _on_stat_changed(n: String, v: float, _m: float) -> void:
	if n == stat_name:
		value = v
		
