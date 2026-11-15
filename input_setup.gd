class_name InputSetup
extends RefCounted
## Crea las acciones de entrada por código si no existen, para no tocar project.godot
## (ese archivo es el que más choca en git). Si ya las definen en Project Settings, no hace nada.

static func ensure() -> void:
	_add("move_left", [KEY_A, KEY_LEFT])
	_add("move_right", [KEY_D, KEY_RIGHT])
	_add("move_up", [KEY_W, KEY_UP])
	_add("move_down", [KEY_S, KEY_DOWN])
	_add("interact", [KEY_E])
	_add("pause", [KEY_ESCAPE])

static func _add(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
