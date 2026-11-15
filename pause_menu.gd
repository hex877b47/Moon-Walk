extends CanvasLayer

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		_alternar()
		get_viewport().set_input_as_handled()

func _alternar() -> void:
	var pausar := not get_tree().paused
	get_tree().paused = pausar
	visible = pausar

func _on_btn_continuar_pressed() -> void:
	_alternar()

func _on_btn_reiniciar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_btn_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
