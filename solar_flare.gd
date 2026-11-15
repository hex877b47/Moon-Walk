extends CanvasLayer
class_name SolarFlareEvent

signal impact_started
signal finished

@onready var tint: ColorRect = $Tint
@onready var panel: Control = $WarningPanel
@onready var bar: ProgressBar = $WarningPanel/ProgressBar
@onready var label: Label = $WarningPanel/WarningLabel

var warning_total: float
var impact_at: float
var duration_minutes := 36.0
var _impacted := false
var _ending := false
var _blink_tween: Tween

func setup(warning_minutes: float) -> void:
	warning_total = warning_minutes
	impact_at = TimeManager.total_minutes() + warning_minutes
	
func _ready() -> void:
	tint.modulate.a = 0.0
	panel.modulate.a = 1.0
	bar.max_value = 1.0
	bar.value = 1.0

func _process(_delta: float) -> void:
	if _ending:
		return
	var now: float = TimeManager.total_minutes()

	if not _impacted:
		var left: float = impact_at - now
		var ratio: float = clampf(left / warning_total, 0.0, 1.0)
		bar.value = ratio
		bar.self_modulate = _color_for(ratio)
		label.text = _format_left(left)
		if ratio < 0.25:
			start_blink()
		if left <= 0.0:
			_impacted = true
			_on_impact()
	elif now >= impact_at + duration_minutes:
		_ending = true
		_on_end()

func _format_left(minutes: float) -> String:
	var m: int = maxi(ceili(minutes), 0)
	return "Impacto en %d h %02d min" % [m / 60, m % 60]

func _on_impact() -> void:
	stop_blink()
	panel.visible = false
	create_tween().tween_property(tint, "modulate:a", 0.25, 0.5)
	impact_started.emit()
	


func _on_end() -> void:
	var t := create_tween()
	t.tween_property(tint, "modulate:a", 0.0, 1.0)
	await t.finished
	finished.emit()
	queue_free()

func start_blink() -> void:
	if _blink_tween and _blink_tween.is_valid():
		return
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(panel, "modulate:a", 0.3, 0.25)
	_blink_tween.tween_property(panel, "modulate:a", 1.0, 0.25)

func stop_blink() -> void:
	if _blink_tween:
		_blink_tween.kill()
	panel.modulate.a = 1.0

func _color_for(ratio: float) -> Color:
	if ratio > 0.5:
		return Color.GREEN.lerp(Color.YELLOW, (1.0 - ratio) * 2.0)
	return Color.YELLOW.lerp(Color.RED, (0.5 - ratio) * 2.0)
