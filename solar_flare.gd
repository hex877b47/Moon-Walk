extends CanvasLayer
class_name SolarFlareEvent

signal impact_started
signal finished

var warning_total:float
var impact_at: float
var duration_minutes:=36.0
var _impacted:=false

func setup(warning_minutes: float) ->void:
	warning_total=warning_minutes
	impact_at=TimeManager.get_total_minutes() + warning_minutes
	

func _proces(_delta:float)-> void:
	var now:= TimeManager.get_total_minutes()
	if not _impacted:
		var left :=impact_at-now
		$ProgressBar.value=clampf(left/warning_total, 0.0, 1.0)
		$WarningLabel.text = _format_left(left)
		if left<=0.0:
			_impacted=true
			impact_started.emit()
			$AnimationPlayer.play("impact")
		elif now>=impact_at+duration_minutes:
			finished.emit()
			queue_free()


func _format_left(minutes: float) -> String:
	var m:=ceili(minutes)
	return "Impacto en %d h %02d min" % [m/60, m%60]
