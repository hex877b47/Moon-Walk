extends Node2D
## Colisión de la base generada desde sus capas (NO toca la escala ni la posición).
## Sólido = tile de pared, o vacío pegado al piso (huecos negros dentro de la base).
## El exterior de la base queda libre para caminar.
## Va en el nodo raíz de base_espacial.tscn.

const HALO := 2   # celdas de vacío junto al piso que también bloquean

## Abertura de la esclusa (en celdas de la cuadrícula de las paredes: x, y, ancho, alto).
## Aquí se QUITAN las paredes y queda libre; puerta.tscn la tapa mientras no haya EVA.
## Esta: la muesca negra del muro NORTE del salón central (6 celdas de ancho).
## Celda -> mundo (con la base en 396, 269 y escala 0.3): x = 396 + 4.8 * celda_x, y = 269 + 4.8 * celda_y
@export var door_cells := Rect2i(38, 10, 6, 6)

var _floor_cache := {}   # celda -> bool (evita recalcular al revisar vecinos)

@onready var _floor: TileMapLayer = $TileMapLayer
@onready var _walls_a: TileMapLayer = $TileMapLayer/TileMapLayer2
@onready var _walls_b: TileMapLayer = $TileMapLayer/TileMapLayer3


func _ready() -> void:
	# Abrir el hueco de la puerta en las paredes
	for x in range(door_cells.position.x, door_cells.end.x):
		for y in range(door_cells.position.y, door_cells.end.y):
			_walls_a.erase_cell(Vector2i(x, y))
			_walls_b.erase_cell(Vector2i(x, y))

	var rect := _walls_a.get_used_rect().merge(_walls_b.get_used_rect()).grow(HALO + 1)
	var cell := Vector2(_walls_a.tile_set.tile_size)

	# El cuerpo cuelga de la capa de paredes: hereda su posición, escala y rotación.
	var body := StaticBody2D.new()
	body.name = "Paredes"
	_walls_a.add_child(body)

	# Une celdas sólidas contiguas (por fila y luego hacia abajo) en pocos rectángulos.
	var open := {}   # Vector2i(x_inicio, x_fin_exclusivo) -> fila donde empezó el rectángulo
	for y in range(rect.position.y, rect.end.y + 1):
		var next_open := {}
		for run in _solid_runs(y, rect):
			next_open[run] = open.get(run, y)
		for run in open:
			if not next_open.has(run):
				_add_box(body, run.x, open[run], run.y, y, cell)
		open = next_open


func _solid_runs(y: int, rect: Rect2i) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	if y >= rect.end.y:
		return runs
	var x := rect.position.x
	while x < rect.end.x:
		if not _is_solid(Vector2i(x, y)):
			x += 1
			continue
		var start := x
		while x < rect.end.x and _is_solid(Vector2i(x, y)):
			x += 1
		runs.append(Vector2i(start, x))
	return runs


func _is_solid(c: Vector2i) -> bool:
	if door_cells.has_point(c) or _is_floor(c):
		return false
	if _is_wall(c):
		return true
	# Vacío: solo bloquea si toca el piso (así el exterior queda libre)
	for dx in range(-HALO, HALO + 1):
		for dy in range(-HALO, HALO + 1):
			if _is_floor(c + Vector2i(dx, dy)):
				return true
	return false


func _is_wall(c: Vector2i) -> bool:
	return _walls_a.get_cell_source_id(c) != -1 or _walls_b.get_cell_source_id(c) != -1


func _is_floor(c: Vector2i) -> bool:
	if _floor_cache.has(c):
		return _floor_cache[c]
	var result := _compute_floor(c)
	_floor_cache[c] = result
	return result


func _compute_floor(c: Vector2i) -> bool:
	if _is_wall(c):
		return false
	# Centro de la celda de pared -> celda del piso (el piso está rotado 90°)
	var center := _walls_a.to_global(_walls_a.map_to_local(c))
	var floor_cell := _floor.local_to_map(_floor.to_local(center))
	return _floor.get_cell_source_id(floor_cell) != -1


func _add_box(body: StaticBody2D, x0: int, y0: int, x1: int, y1: int, cell: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(x1 - x0, y1 - y0) * cell
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(x0, y0) * cell + shape.size / 2.0
	body.add_child(col)
