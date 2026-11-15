extends Node2D
## Escena principal: base + jugador + estaciones + HUD. Maneja noche, mensajes y fin de partida.

const NIGHT_COLOR := Color(0.32, 0.38, 0.62)
const FLARE_SCENE := preload("res://solar_wave.tscn")
const END_DELAY := 1.5   # segundos para ver la animación "dead" antes de la pantalla de fin

@onready var _night: CanvasModulate = $Night
@onready var _msg: Label = $UI/Message
@onready var _game_over: CanvasLayer = $GameOver

var _msg_left := 0.0


func _ready() -> void:
	InputSetup.ensure()
	_msg.text = ""
	EventBus.message.connect(_show_message)
	Stats.player_died.connect(_on_died)
	Stats.game_won.connect(_on_won)
	EventBus.message.emit("Sobrevive hasta el día %d. Mueve con WASD, interactúa con E." % Stats.GOAL_DAY)
	EventBus.flare_warning.connect(_on_flare_warning)


func _process(delta: float) -> void:
	var h := TimeManager.time_of_day / 60.0
	var dawn := smoothstep(TimeManager.SUNRISE_HOUR - 1.0, TimeManager.SUNRISE_HOUR + 1.0, h)
	var dusk := 1.0 - smoothstep(TimeManager.SUNSET_HOUR - 1.0, TimeManager.SUNSET_HOUR + 1.0, h)
	_night.color = NIGHT_COLOR.lerp(Color.WHITE, dawn * dusk)
	if _msg_left > 0.0:
		_msg_left -= delta
		if _msg_left <= 0.0:
			_msg.text = ""


func _show_message(text: String) -> void:
	_msg.text = text
	_msg_left = 6.0


func _on_died(reason: String) -> void:
	_end("GAME OVER", "%s\nDía %d · Ciencia %d" % [reason, TimeManager.day, Stats.science])


func _on_won(d: int, sci: int) -> void:
	_end("¡SOBREVIVISTE!", "Llegaste al día %d\nCiencia: %d" % [d, sci])


func _end(titulo: String, detalle: String) -> void:
	await get_tree().create_timer(END_DELAY).timeout
	_game_over.mostrar(titulo, detalle)

func _on_flare_warning(seconds: float) -> void:
	var ev := FLARE_SCENE.instantiate() as SolarFlareEvent
	add_child(ev)
	ev.setup(seconds * TimeManager.MINUTES_PER_DAY / TimeManager.day_length_seconds)
	ev.duration_minutes = Stats.FLARE_DURATION_H * 60.0
