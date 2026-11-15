extends Node

signal tick(time: float)

@export var time:= 0.0
var speed := 1.0
var running:= true

func _process(delta):
	if running:
		time+=delta*speed
		tick.emit(time)
