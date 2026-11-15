extends CanvasLayer

var _queue: Array[InfoMessage] = []
var _current: InfoMessage = null
var _seen := {}
var _panel: PanelContainer
var _title: Label
var _body: Label
var _source: Label
var _tween: Tween
var _game_was_paused := false

func _ready() -> void:
	layer = 20
	_build_ui()
	_panel.visible = false

# Acepta cualquier objeto que tenga to_message()
func show_from(obj) -> void:
	if obj == null or not obj.has_method("to_message"):
		push_warning("Messages: el objeto no tiene to_message()")
		return
	show_message(obj.to_message())

func show_message(msg: InfoMessage) -> void:
	if msg.once_key != "":
		if _seen.has(msg.once_key):
			return
		_seen[msg.once_key] = true
	if _current == null:
		_display(msg)
	elif msg.priority > _current.priority:
		_queue.push_front(_current)   # el interrumpido vuelve después
		_display(msg)
	else:
		_queue.append(msg)

func _display(msg: InfoMessage) -> void:
	if _tween:
		_tween.kill()
	_release_pause()
	_current = msg
	_title.text = msg.title
	_title.add_theme_color_override("font_color", msg.accent)
	_body.text = msg.body
	_source.text = msg.source

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.93)
	sb.border_color = msg.accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", sb)

	_panel.visible = true
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	if msg.pause_game:
		_game_was_paused = TimeManager.paused
		TimeManager.paused = true
		_source.text += "   ·   Espacio para continuar"
	else:
		_tween.tween_interval(msg.duration)
		_tween.tween_property(_panel, "modulate:a", 0.0, 0.4)
		_tween.finished.connect(_close)

func _unhandled_input(event: InputEvent) -> void:
	if _current != null and _current.pause_game and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	_release_pause()
	_panel.visible = false
	_current = null
	if not _queue.is_empty():
		_display(_queue.pop_front())

func _release_pause() -> void:
	if _current != null and _current.pause_game:
		TimeManager.paused = _game_was_paused

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -280
	_panel.offset_right = 280
	_panel.offset_top = -330
	_panel.offset_bottom = -150
	root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	box.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(520, 0)
	box.add_child(_body)

	_source = Label.new()
	_source.add_theme_font_size_override("font_size", 12)
	_source.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_source)
