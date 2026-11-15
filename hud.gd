extends Control
## Teclas de depuración (quitar antes de entregar):
## F1 llamarada · F2 EVA on/off · F3 refugio on/off · F4 velocidad x1/x5/x10 · F5 romper un módulo

const SPEEDS := [1.0, 5.0, 10.0]
var _speed_idx := 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				Stats.trigger_flare()
			KEY_F2:
				if Stats.in_eva:
					Stats.end_eva()
				else:
					Stats.begin_eva()
			KEY_F3:
				Stats.set_shelter(not Stats.in_shelter)
			KEY_F4:
				_speed_idx = (_speed_idx + 1) % SPEEDS.size()
				TimeManager.time_scale = SPEEDS[_speed_idx]
				EventBus.message.emit("Velocidad del tiempo x%d" % int(SPEEDS[_speed_idx]))
			KEY_F5:
				EventDirector.break_random(1)
