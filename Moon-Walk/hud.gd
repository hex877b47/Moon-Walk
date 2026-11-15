extends Control
## Teclas de depuración (quitar antes de entregar):
## F1 llamarada con aviso (real, NASA) · F6 llamarada instantánea · F7 mensaje de llamarada
## F2 EVA on/off · F3 refugio on/off · F4 velocidad x1/x5/x10 · F5 romper un módulo
## Bloq Mayús: mensaje de mineral (Ilmenita)

const SPEEDS := [1.0, 5.0, 10.0]
var _speed_idx := 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				Stats.spawn_flare_event()
			KEY_F6:
				Stats.trigger_flare()
			KEY_F7:
				if not Stats.flare_pool.is_empty():
					Messages.show_from(Stats.flare_pool.pick_random())
			KEY_CAPSLOCK:
				Messages.show_from(load("res://Ilmenita.tres"))
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
