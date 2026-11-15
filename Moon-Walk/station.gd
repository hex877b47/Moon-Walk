class_name Station
extends Area2D
## Estación interactuable. Pon una instancia por módulo y elige `kind` en el Inspector.
## Averiado: mantén E para reparar. Refugio: automático al entrar. Esclusa: E sale/entra de EVA.

@export_enum("oxygen_generator", "water_recycler", "greenhouse", "solar_panels", "shelter", "airlock") var kind: String = "oxygen_generator"
@export var repair_seconds := 1.5

const COLORS := {
	"oxygen_generator": Color(0.2, 0.85, 0.85),
	"water_recycler": Color(0.25, 0.55, 1.0),
	"greenhouse": Color(0.3, 0.85, 0.3),
	"solar_panels": Color(1.0, 0.85, 0.2),
	"shelter": Color(0.6, 0.6, 0.65),
	"airlock": Color(0.9, 0.5, 0.2),
}

var _inside := false
var _hold := 0.0

@onready var _rect: ColorRect = $Rect
@onready var _label: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_rect.color = COLORS.get(kind, Color.WHITE)
	_label.visible = false


func _on_enter(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_inside = true
	if kind == "shelter":
		Stats.set_shelter(true)


func _on_exit(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_inside = false
	_hold = 0.0
	_label.visible = false
	if kind == "shelter":
		Stats.set_shelter(false)


func _process(delta: float) -> void:
	var is_broken: bool = Stats.is_broken(kind)
	_rect.modulate = Color(1.0, 0.3, 0.3) if is_broken else Color.WHITE
	if not _inside or Stats.is_dead or Stats.won:
		return
	_label.visible = true

	if is_broken:
		if Input.is_action_pressed("interact"):
			_hold += delta
			if _hold >= repair_seconds:
				_hold = 0.0
				Stats.repair_module(kind)
		else:
			_hold = 0.0
		_label.text = "Mantén [E] para reparar %d %%" % int(_hold / repair_seconds * 100.0)
		return

	var pressed := Input.is_action_just_pressed("interact")
	match kind:
		"greenhouse":
			if Stats.harvest_ready:
				_label.text = "[E] Cosechar"
				if pressed:
					Stats.harvest()
			else:
				_label.text = "Creciendo... %d %%" % int(Stats.greenhouse_progress / Stats.GREENHOUSE_GROW_MINUTES * 100.0)
		"airlock":
			_label.text = "[E] Volver a la base" if Stats.in_eva else "[E] Salir (EVA)"
			if pressed:
				if Stats.in_eva:
					Stats.end_eva()
				elif not Stats.begin_eva():
					EventBus.message.emit("No hay suficiente O2 o energía para salir.")
		"shelter":
			_label.text = "Refugio: la radiación baja"
		_:
			_label.text = "%s: operativo" % Stats.MODULE_NAMES.get(kind, kind)
