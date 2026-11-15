extends StaticBody2D
## Puerta de la esclusa. Cerrada = bloquea el paso; se abre mientras haya EVA activa.
## Si la escena tiene un nodo hijo "Visual", se usa ese diseño; si no, dibuja uno por defecto.

@export var size := Vector2(28.8, 9.6)   # tamaño de la abertura en px de mundo (solo colisión)
@export var open_alpha := 0.12           # cuánto se ve la puerta abierta (0 = invisible)
@export var open_time := 0.35            # segundos que tarda en abrir/cerrar

var _col: CollisionShape2D
var _visual: Node2D
var _tween: Tween


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	_col = CollisionShape2D.new()
	_col.shape = shape
	add_child(_col)

	_visual = get_node_or_null("Visual")
	if _visual == null:
		_visual = Node2D.new()
		_visual.name = "Visual"
		add_child(_visual)
		_build_default_look()

	Stats.eva_changed.connect(_set_open)
	_set_open(Stats.in_eva, true)


func _build_default_look() -> void:
	var plate := ColorRect.new()
	plate.size = size
	plate.position = -size / 2.0
	plate.color = Color(0.33, 0.38, 0.48)          # <- color de la placa
	_visual.add_child(plate)
	for y in [-size.y / 2.0, size.y / 2.0 - 3.0]:
		var bar := ColorRect.new()
		bar.size = Vector2(size.x, 3.0)
		bar.position = Vector2(-size.x / 2.0, y)
		bar.color = Color(0.95, 0.75, 0.15)         # <- franjas
		_visual.add_child(bar)


func _set_open(open: bool, instant: bool = false) -> void:
	_col.set_deferred("disabled", open)
	if _tween:
		_tween.kill()
	var target := open_alpha if open else 1.0
	if instant:
		_visual.modulate.a = target
	else:
		_tween = create_tween()
		_tween.tween_property(_visual, "modulate:a", target, open_time)
