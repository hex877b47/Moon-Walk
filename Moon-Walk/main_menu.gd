extends Control

const GAME_SCENE := "res://main.tscn"   # antes apuntaba a esenario1.tscn (sin jugador, HUD ni pausa)

@onready var _btn_iniciar: Button = $AspectRatioContainer/Panel/BtnIniciar
@onready var _btn_salir: Button = $AspectRatioContainer/Panel/BtnSalir


func _ready() -> void:
	get_tree().paused = false
	_conectar(_btn_iniciar, _on_btn_iniciar_pressed)
	_conectar(_btn_salir, _on_btn_salir_pressed)


## Conecta por código solo si no está ya conectado desde el editor.
func _conectar(btn: Button, f: Callable) -> void:
	if not btn.pressed.is_connected(f):
		btn.pressed.connect(f)


func _on_btn_iniciar_pressed() -> void:
	Stats.reset()   # partida limpia aunque vengas de morir
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_btn_salir_pressed() -> void:
	get_tree().quit()
