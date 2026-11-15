extends CanvasLayer

@onready var _btn_continuar: Button = $AspectRatioContainer/Panel/BtnContinuar
@onready var _btn_reiniciar: Button = $AspectRatioContainer/Panel/BtnReiniciar
@onready var _btn_salir: Button = $AspectRatioContainer/Panel/BtnSalir


func _ready() -> void:
	InputSetup.ensure()   # define la acción "pausa" (Esc) si no existe
	hide()
	_conectar(_btn_continuar, _on_btn_continuar_pressed)
	_conectar(_btn_reiniciar, _on_btn_reiniciar_pressed)
	_conectar(_btn_salir, _on_btn_salir_pressed)


func _conectar(btn: Button, f: Callable) -> void:
	if not btn.pressed.is_connected(f):
		btn.pressed.connect(f)


func _unhandled_input(event: InputEvent) -> void:
	if Stats.is_dead or Stats.won:
		return   # con la pantalla de fin de partida, Esc no abre la pausa
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
	Stats.reset()   # sin esto reiniciaba la escena pero con los medidores y el reloj anteriores
	get_tree().reload_current_scene()


func _on_btn_salir_pressed() -> void:
	get_tree().paused = false
	Stats.reset()
	get_tree().change_scene_to_file("res://main_menu.tscn")
