extends CanvasLayer
## Pantalla de fin de partida (muerte o victoria). Misma estructura que pause_menu.

@onready var _titulo: Label = $AspectRatioContainer/Panel/Titulo
@onready var _detalle: Label = $AspectRatioContainer/Panel/Detalle
@onready var _btn_reiniciar: Button = $AspectRatioContainer/Panel/BtnReiniciar
@onready var _btn_salir: Button = $AspectRatioContainer/Panel/BtnSalir


func _ready() -> void:
	hide()
	_btn_reiniciar.pressed.connect(_on_btn_reiniciar_pressed)
	_btn_salir.pressed.connect(_on_btn_salir_pressed)


func mostrar(titulo: String, detalle: String) -> void:
	_titulo.text = titulo
	_detalle.text = detalle
	show()
	get_tree().paused = true
	_btn_reiniciar.grab_focus()


func _on_btn_reiniciar_pressed() -> void:
	get_tree().paused = false
	Stats.reset()
	get_tree().reload_current_scene()


func _on_btn_salir_pressed() -> void:
	get_tree().paused = false
	Stats.reset()
	get_tree().change_scene_to_file("res://main_menu.tscn")
