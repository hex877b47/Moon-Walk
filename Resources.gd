class_name SolarEvent
extends Resource

@export var id: String = "flare_m"
@export var display_name: String = "Llamarada solar clase M"
@export var warning_time: float = 20.0   # seg de aviso antes del impacto
@export var duration: float = 15.0       # seg que dura la radiación
@export var radiation_damage: float = 30.0
@export var power_drain: float = 0.0
@export_multiline var explanation: String = "Las llamaradas son explosiones en el Sol..."
