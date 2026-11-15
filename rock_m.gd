class_name Rock
extends StaticBody2D
## Roca minable. Estructura de la escena:
## Rock (StaticBody2D)  <- este script
##   ├─ Sprite2D
##   └─ CollisionShape2D
 
signal depleted
 
@export var max_health: int = 5
@export var resource_name: String = "Piedra"
@export var min_amount: int = 1
@export var max_amount: int = 3
@export var region: Rect2 = Rect2()   # recorte de la imagen para esta roca
 
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionPolygon2D = $CollisionPolygon2D
 
var health: int
 
 
func _ready() -> void:
	health = max_health
	add_to_group("minable")
	if region.size != Vector2.ZERO:
		sprite.region_enabled = true
		sprite.region_rect = region
	# Cada roca usa su propia copia de la forma de colisión
 
 
## El jugador llama a esta función cada vez que golpea la roca.
func hit(damage: int = 1) -> void:
	health -= damage
	_play_hit_effect()
	if health <= 0:
		_deplete()
 
 
func _play_hit_effect() -> void:
	var tween := create_tween()
	modulate = Color(1.5, 1.5, 1.5)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	var start_pos := position
	position += Vector2(randf_range(-2, 2), randf_range(-2, 2))
	tween.parallel().tween_property(self, "position", start_pos, 0.15)
 
 
func _deplete() -> void:
	var amount := randi_range(min_amount, max_amount)
	Inventario.add_item(resource_name, amount)
	print("Obtuviste %d x %s" % [amount, resource_name])
	depleted.emit()
	queue_free()
