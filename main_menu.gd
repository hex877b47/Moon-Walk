extends Control

const GAME_SCENE := "res://esenario1.tscn"

func _on_btn_iniciar_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
