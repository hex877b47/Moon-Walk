extends CanvasLayer
class_name SolarFlareEvent

signal impact_started
signal finished

var impact_time: float
var duration:=15.0
var _impacted:=false

func setup(warning_time: float):
	impact_time=gameclock.time +warning_time
