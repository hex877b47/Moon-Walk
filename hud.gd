extends Control
## Teclas de depuración (quitar antes de entregar):
## F1 llamarada · F2 EVA on/off · F3 refugio on/off · F4 velocidad x1/x5/x10 · F5 romper un módulo
## F8 desgasta el pico 35 % (prueba de la mesa de reparaciones)

const SPEEDS := [1.0, 5.0, 10.0]
var _speed_idx := 0
var _info: Label   # herramientas + inventario (abajo a la izquierda)


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_info = Label.new()
	_info.anchor_top = 1.0
	_info.anchor_bottom = 1.0
	_info.offset_left = 12.0
	_info.offset_top = -12.0
	_info.offset_bottom = -12.0
	_info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_info.add_theme_font_size_override("font_size", 12)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 4)
	layer.add_child(_info)
	Stats.tool_changed.connect(func(_t, _d): _refresh_info())
	Inventario.item_changed.connect(func(_n, _a): _refresh_info())
	_refresh_info()


func _refresh_info() -> void:
	var lines: Array[String] = []
	var worn := false
	for t in Stats.tool_durability:
		var d: int = int(Stats.tool_durability[t])
		worn = worn or d <= int(Stats.TOOL_WARN_LEVEL)
		lines.append("%s %d %%" % [Stats.TOOL_NAMES[t], d])
	for item_name in Inventario.items:
		if Inventario.items[item_name] > 0:
			lines.append("%s x%d" % [item_name, Inventario.items[item_name]])
	_info.text = "\n".join(lines)
	_info.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3) if worn else Color.WHITE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				EventDirector._flare()
			KEY_F2:
				if Stats.in_eva:
					Stats.end_eva()
				else:
					Stats.begin_eva()
			KEY_F3:
				Stats.set_shelter(not Stats.in_shelter)
			KEY_F4:
				_speed_idx = (_speed_idx + 1) % SPEEDS.size()
				TimeManager.time_scale = SPEEDS[_speed_idx]
				EventBus.message.emit("Velocidad del tiempo x%d" % int(SPEEDS[_speed_idx]))
			KEY_F5:
				EventDirector.break_random(1)
			KEY_F8:
				Stats.use_tool("pickaxe", 35.0)
