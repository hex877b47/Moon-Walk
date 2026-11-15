extends Control

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1: Stats.spawn_flare_event()
			KEY_F2: Stats.start_eva(20.0)
			KEY_F3: Stats.set_shelter(not Stats.in_shelter)
			KEY_F4: TimeManager.day_length_seconds = 20.0
			KEY_F5: Stats.modules["oxygen_generator"] = not Stats.modules["oxygen_generator"]
			KEY_F7:Messages.show_from(Stats.flare_pool.pick_random())
			KEY_CAPSLOCK:
				Messages.show_from(load("res://Ilmenita.tres"))
