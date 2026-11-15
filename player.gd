extends CharacterBody2D

const SPEED := 90.0
const DEFAULT_SCALE := Vector2(0.3, 0.3)

# Diccionario de escalas fijas por animación
const ANIM_SCALES := {
	"idle_down": Vector2(0.087, 0.084),
	"walk_side": Vector2(0.054, 0.052),
	"walk_down": Vector2(0.029, 0.028),
	"walk_up": Vector2(0.033, 0.029),
	"dead": Vector2(0.2, 0.2),
}

var facing := Vector2.DOWN

@onready var _anim: AnimatedSprite2D = $Sprite


func _ready() -> void:
	InputSetup.ensure()
	add_to_group("player")
	
	# Conectamos el cambio de animación para aplicar la escala fija correspondiente
	_anim.animation_changed.connect(_apply_anim_scale)
	Stats.player_died.connect(func(_reason): _anim.play("dead"))
	
	# Aplicamos la escala inicial
	_apply_anim_scale()


func _physics_process(_delta: float) -> void:
	if Stats.is_dead or Stats.won:
		velocity = Vector2.ZERO
		return
		
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = dir
		
	velocity = dir * SPEED
	move_and_slide()
	_update_animation(dir)


func _update_animation(dir: Vector2) -> void:
	var next_anim := "idle_down"
	
	if dir != Vector2.ZERO:
		var side := "side"
		if absf(facing.y) > absf(facing.x):
			side = "down" if facing.y > 0.0 else "up"
			_anim.flip_h = false # Evita que arriba/abajo queden invertidos
		else:
			_anim.flip_h = facing.x < 0.0
		next_anim = "walk_" + side
	else:
		_anim.flip_h = false # Asegura que idle_down no quede volteado
		
	if _anim.animation != next_anim:
		_anim.play(next_anim)


## Aplica la escala predefinida del diccionario según la animación actual
func _apply_anim_scale() -> void:
	_anim.scale = ANIM_SCALES.get(_anim.animation, DEFAULT_SCALE)
