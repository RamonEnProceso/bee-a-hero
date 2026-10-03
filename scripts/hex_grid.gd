class_name HexGrid
extends Node2D

## Distancia del centro de cada hexágono a sus vértices, en píxeles.
@export var hex_size: float = 32.0
## Cuántos "anillos" de hexágonos se dibujan alrededor del centro (0,0).
@export var grid_radius: int = 12

# Colores placeholder del panal.
@export var fill_color: Color = Color(0.95, 0.72, 0.20)
@export var outline_color: Color = Color(0.55, 0.38, 0.10)
@export var hover_color: Color = Color(1.0, 0.92, 0.45)
## Escena de la pared que se construye.
@export var wall_scene: PackedScene
## Escena de la torre (el aguijón) que se construye.
@export var tower_scene: PackedScene
## Escena de la pared reforzada (más vida, contra avispones).
@export var reinforced_wall_scene: PackedScene
## Escena de la pared de púas (devuelve daño al que la golpea).
@export var spiky_wall_scene: PackedScene

# Celda sobre la que está el mouse en este instante.
var hovered: Vector2i = Vector2i.ZERO
# Paredes construidas: clave = celda (Vector2i), valor = nodo Wall.
var walls: Dictionary = {}
# Torres construidas: clave = celda (Vector2i), valor = nodo Tower.
var towers: Dictionary = {}

# --- Vista previa mientras arrastramos una tarjeta (main.gd la actualiza) ---
var show_build_range: bool = false
var build_center: Vector2 = Vector2.ZERO
var build_range_px: float = 0.0
var preview_cell: Vector2i = Vector2i.ZERO
var preview_mouse_world: Vector2 = Vector2.ZERO
var preview_texture: Texture2D
var preview_valid: bool = false


func _ready() -> void:
	# La grilla queda en el origen (0,0); la cámara que sigue a la abeja muestra la vista.
	queue_redraw()


func _process(_delta: float) -> void:
	# Solo redibujamos cuando el mouse cambia de celda (menos carga que redibujar cada frame).
	var cell: Vector2i = pixel_to_hex(to_local(get_global_mouse_position()))
	if cell != hovered:
		hovered = cell
		queue_redraw()


# ---------------------------------------------------------------------------
# Matemática de coordenadas hexagonales axiales (pointy-top, Red Blob Games).
# ---------------------------------------------------------------------------

## Convierte coordenadas axiales (q, r) a la posición en píxeles del centro del hexágono.
func hex_to_pixel(q: int, r: int) -> Vector2:
	var x: float = hex_size * sqrt(3.0) * (float(q) + float(r) / 2.0)
	var y: float = hex_size * 1.5 * float(r)
	return Vector2(x, y)


## Convierte una posición en píxeles (local a la grilla) a coordenadas axiales.
func pixel_to_hex(pos: Vector2) -> Vector2i:
	var qf: float = (sqrt(3.0) / 3.0 * pos.x - pos.y / 3.0) / hex_size
	var rf: float = (2.0 / 3.0 * pos.y) / hex_size
	return cube_round(qf, rf)


## Redondea coordenadas cúbicas fraccionarias a la celda entera más cercana.
func cube_round(qf: float, rf: float) -> Vector2i:
	var sf: float = -qf - rf
	var rq: int = roundi(qf)
	var rr: int = roundi(rf)
	var rs: int = roundi(sf)

	var q_diff: float = abs(float(rq) - qf)
	var r_diff: float = abs(float(rr) - rf)
	var s_diff: float = abs(float(rs) - sf)

	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	else:
		rs = -rq - rs

	return Vector2i(rq, rr)


## Posición en coordenadas del mundo de una celda axial (tiene en cuenta el offset de la grilla).
func world_position_of(q: int, r: int) -> Vector2:
	return to_global(hex_to_pixel(q, r))


## Celdas del anillo de radio `radius` (por defecto el borde exterior). Sirve para
## spawnear enemigos en el borde y para colocar las abejas suicidas alrededor de la reina.
func get_ring_cells(radius: int = -1) -> Array[Vector2i]:
	var rad: int = grid_radius if radius < 0 else radius
	var cells: Array[Vector2i] = []
	for q in range(-rad, rad + 1):
		var r_min: int = maxi(-rad, -q - rad)
		var r_max: int = mini(rad, -q + rad)
		for r in range(r_min, r_max + 1):
			if cube_radius(q, r) == rad:
				cells.append(Vector2i(q, r))
	return cells


## Las 6 celdas vecinas de `cell` (direcciones axiales).
func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]:
		out.append(cell + d)
	return out


## Radio "cúbico" de una celda: max(|q|, |r|, |q+r|).
func cube_radius(q: int, r: int) -> int:
	return maxi(absi(q), maxi(absi(r), absi(q + r)))


## Distancia entre dos celdas en pasos hexagonales (distancia cúbica).
func cube_distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = absi(a.x - b.x)
	var dr: int = absi(a.y - b.y)
	var ds: int = absi((a.x + a.y) - (b.x + b.y))
	return maxi(dq, maxi(dr, ds))


## Celda que contiene una posición del mundo (el enemigo la usa para detectar estructuras).
func cell_at_world(pos: Vector2) -> Vector2i:
	return pixel_to_hex(to_local(pos))


## ¿Se puede construir en `cell`? (libre, no es el centro y no es el borde).
func can_place(cell: Vector2i) -> bool:
	if walls.has(cell) or towers.has(cell):
		return false
	if cell == Vector2i.ZERO:
		return false  # la reina ocupa (0,0)
	if cube_radius(cell.x, cell.y) >= grid_radius:
		return false  # no construir en el borde donde spawnean enemigos
	return true


## Devuelve la pared en `cell`, o null si no hay.
func wall_at(cell: Vector2i) -> Wall:
	return walls.get(cell)


## Devuelve la torre en `cell`, o null si no hay.
func tower_at(cell: Vector2i) -> Tower:
	return towers.get(cell)


## Devuelve la estructura (pared o torre) en `cell`, o null si no hay.
## Sin tipo de retorno: los enemigos llaman .take_damage() sobre lo que devuelva.
func structure_at(cell: Vector2i):
	if walls.has(cell):
		return walls[cell]
	if towers.has(cell):
		return towers[cell]
	return null


## Construye la estructura del `type` pedido en `cell`. Devuelve el nodo o null.
func build(type: int, cell: Vector2i) -> Node2D:
	match type:
		Game.BuildType.WALL:
			return build_wall(cell)
		Game.BuildType.TOWER:
			return build_tower(cell)
		Game.BuildType.REINFORCED:
			return build_reinforced_wall(cell)
		Game.BuildType.SPIKY:
			return build_spiky_wall(cell)
	return null


## Construye una pared normal en `cell`. Devuelve null si la celda no es válida.
func build_wall(cell: Vector2i) -> Wall:
	return _build_wall_with(wall_scene, cell)


## Construye una pared reforzada (más vida) en `cell`.
func build_reinforced_wall(cell: Vector2i) -> Wall:
	return _build_wall_with(reinforced_wall_scene, cell)


## Construye una pared de púas (devuelve daño) en `cell`.
func build_spiky_wall(cell: Vector2i) -> Wall:
	return _build_wall_with(spiky_wall_scene, cell)


## Pared genérica: instancia la escena, la anota en `walls` y la coloca en su celda.
func _build_wall_with(scene: PackedScene, cell: Vector2i) -> Wall:
	if scene == null:
		return null
	if not can_place(cell):
		return null

	var wall: Wall = scene.instantiate()
	wall.grid = self
	wall.cell = cell
	wall.hex_size = hex_size
	wall.position = hex_to_pixel(cell.x, cell.y)
	walls[cell] = wall
	add_child(wall)
	return wall


## Saca una pared del diccionario (la llama Wall._break al romperse).
func remove_wall(cell: Vector2i) -> void:
	walls.erase(cell)


## Construye una torre en `cell`. Devuelve null si la celda no es válida.
func build_tower(cell: Vector2i) -> Tower:
	if tower_scene == null:
		return null
	if not can_place(cell):
		return null

	var tower: Tower = tower_scene.instantiate()
	tower.grid = self
	tower.cell = cell
	tower.hex_size = hex_size
	tower.position = hex_to_pixel(cell.x, cell.y)
	towers[cell] = tower
	add_child(tower)
	return tower


## Saca una torre del diccionario (la llama Tower.die al destruirse).
func remove_tower(cell: Vector2i) -> void:
	towers.erase(cell)


# ---------------------------------------------------------------------------
# Dibujo.
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Todas las celdas del panal.
	for q in range(-grid_radius, grid_radius + 1):
		var r_min: int = maxi(-grid_radius, -q - grid_radius)
		var r_max: int = mini(grid_radius, -q + grid_radius)
		for r in range(r_min, r_max + 1):
			var cell: Vector2i = Vector2i(q, r)
			var color: Color = hover_color if cell == hovered else fill_color
			_draw_hexagon(hex_to_pixel(q, r), color)

	# Círculo de rango de construcción (visible mientras arrastramos una tarjeta).
	if show_build_range:
		var lc: Vector2 = to_local(build_center)
		draw_circle(lc, build_range_px, Color(0.3, 0.8, 0.4, 0.12))
		draw_arc(lc, build_range_px, 0.0, TAU, 64, Color(0.3, 0.8, 0.4, 0.6), 2.0, true)

	# Vista previa: celda destino (verde/rojo) + fantasma siguiendo el mouse.
	if preview_texture != null:
		var pc: Vector2 = hex_to_pixel(preview_cell.x, preview_cell.y)
		var cc: Color = Color(0.2, 0.9, 0.3, 0.5) if preview_valid else Color(0.9, 0.2, 0.2, 0.5)
		_draw_hexagon(pc, cc)

		var s: float = hex_size * 1.8
		var mp: Vector2 = to_local(preview_mouse_world)
		draw_texture_rect(preview_texture, Rect2(mp - Vector2(s, s) / 2.0, Vector2(s, s)), false, Color(1, 1, 1, 0.7))


## Dibuja un solo hexágono (punto-arriba) relleno y con contorno.
func _draw_hexagon(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 6:
		var angle: float = deg_to_rad(60.0 * i - 30.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * hex_size)

	draw_colored_polygon(points, color)

	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, outline_color, 2.0, true)
