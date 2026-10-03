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
## Escena de la pared trampa (pinchos: desaparecen al tocar y dañan).
@export var trap_wall_scene: PackedScene
## Escena de la torre doble (recarga a la mitad de tiempo).
@export var double_tower_scene: PackedScene
## Escena del cañón (ocupa 2x2 hexágonos, tiros potentes).
@export var big_tower_scene: PackedScene
## Escena del edificio base (ocupa 3 hexágonos, habilita 3 slots).
@export var building_scene: PackedScene
## Escena de la guardería (regala una torre por oleada).
@export var guarderia_scene: PackedScene
## Escena de la cultivadora (genera miel por oleada).
@export var cultivadora_scene: PackedScene
## Escena del aliado guardia (cuerpo a cuerpo).
@export var guardia_scene: PackedScene
## Escena del aliado de largo alcance (francotirador).
@export var long_range_scene: PackedScene
## Escena del aliado pirañas (enjambre de 4 slots, corto alcance).
@export var piranas_scene: PackedScene

# Celda sobre la que está el mouse en este instante.
var hovered: Vector2i = Vector2i.ZERO
# Paredes construidas: clave = celda (Vector2i), valor = nodo Wall.
var walls: Dictionary = {}
# Torres construidas: clave = celda (Vector2i), valor = nodo Tower.
var towers: Dictionary = {}
# Trampas (pared trampa): clave = celda (Vector2i), valor = nodo TrapWall. No bloquean.
var traps: Dictionary = {}
# Edificios: clave = celda (Vector2i), valor = nodo Building. Ocupan 3 celdas cada uno.
var buildings: Dictionary = {}

## Desplazamientos que ocupa el cañón (un "2x2" de hexágonos contiguos).
const BIG_TOWER_FOOTPRINT := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(1, -1)]
## Desplazamientos que ocupa un edificio base (triángulo de 3 hexágonos contiguos).
const BUILDING_FOOTPRINT := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)]

# --- Vista previa mientras arrastramos una tarjeta (main.gd la actualiza) ---
var show_build_range: bool = false
var build_center: Vector2 = Vector2.ZERO
var build_range_px: float = 0.0
var preview_cell: Vector2i = Vector2i.ZERO
var preview_mouse_world: Vector2 = Vector2.ZERO
var preview_texture: Texture2D
var preview_valid: bool = false
var preview_type: int = -1


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
	if walls.has(cell) or towers.has(cell) or traps.has(cell) or buildings.has(cell):
		return false
	if cell == Vector2i.ZERO:
		return false  # la reina ocupa (0,0)
	if cube_radius(cell.x, cell.y) >= grid_radius:
		return false  # no construir en el borde donde spawnean enemigos
	return true


## ¿Se puede construir el `type` en `cell`? Valida todo el footprint (el cañón ocupa 2x2).
func can_place_build(type: int, cell: Vector2i) -> bool:
	if type == Game.BuildType.BIG_TOWER:
		for c in _big_tower_cells(cell):
			if not can_place(c):
				return false
		return true
	if _is_building(type):
		for c in _building_cells(cell):
			if not can_place(c):
				return false
		return true
	return can_place(cell)


## ¿El `type` es un edificio (ocupa 3 hexágonos)?
func _is_building(type: int) -> bool:
	return type == Game.BuildType.BASE or type == Game.BuildType.GUARDERIA or type == Game.BuildType.CULTIVADORA


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
	if buildings.has(cell):
		var b = buildings[cell]
		# Un edificio en construcción ocupa la celda pero no se puede atacar.
		if b.built:
			return b
		return null
	return null


## Construye la estructura del `type` pedido en `cell`. Devuelve el nodo o null.
func build(type: int, cell: Vector2i) -> Node2D:
	match type:
		Game.BuildType.WALL:
			return build_wall(cell)
		Game.BuildType.REINFORCED:
			return build_reinforced_wall(cell)
		Game.BuildType.TRAP:
			return build_trap(cell)
		Game.BuildType.TOWER:
			return build_tower(cell)
		Game.BuildType.DOUBLE_TOWER:
			return build_double_tower(cell)
		Game.BuildType.BIG_TOWER:
			return build_big_tower(cell)
		Game.BuildType.BASE:
			return build_building(cell)
		Game.BuildType.GUARDERIA:
			return build_guarderia(cell)
		Game.BuildType.CULTIVADORA:
			return build_cultivadora(cell)
		Game.BuildType.GUARDIA:
			return build_guardia(cell)
		Game.BuildType.LONG_RANGE:
			return build_long_range(cell)
		Game.BuildType.PIRANAS:
			return build_piranas(cell)
	return null


## Construye una pared normal en `cell`. Devuelve null si la celda no es válida.
func build_wall(cell: Vector2i) -> Wall:
	return _build_wall_with(wall_scene, cell)


## Construye una pared reforzada (más vida) en `cell`.
func build_reinforced_wall(cell: Vector2i) -> Wall:
	return _build_wall_with(reinforced_wall_scene, cell)


## Construye una pared trampa (pinchos) en `cell`. No bloquea: es un consumible.
func build_trap(cell: Vector2i) -> TrapWall:
	if trap_wall_scene == null:
		return null
	if not can_place(cell):
		return null
	var trap: TrapWall = trap_wall_scene.instantiate()
	trap.grid = self
	trap.cell = cell
	trap.hex_size = hex_size
	trap.position = hex_to_pixel(cell.x, cell.y)
	traps[cell] = trap
	add_child(trap)
	return trap


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


## Saca una trampa del diccionario (la llama TrapWall._trigger al consumirse).
func remove_trap(cell: Vector2i) -> void:
	traps.erase(cell)


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
	tower.cells = [cell]
	tower.position = hex_to_pixel(cell.x, cell.y)
	towers[cell] = tower
	add_child(tower)
	return tower


## Construye una torre doble (recarga a la mitad de tiempo) en `cell`.
func build_double_tower(cell: Vector2i) -> Tower:
	if double_tower_scene == null:
		return null
	if not can_place(cell):
		return null

	var tower: Tower = double_tower_scene.instantiate()
	tower.grid = self
	tower.cell = cell
	tower.hex_size = hex_size
	tower.cells = [cell]
	tower.position = hex_to_pixel(cell.x, cell.y)
	towers[cell] = tower
	add_child(tower)
	return tower


## Construye un cañón (2x2 hexágonos) anclado en `cell`. El nodo queda centrado
## en el centro geométrico del footprint y se anota bajo las 4 celdas.
func build_big_tower(cell: Vector2i) -> Tower:
	if big_tower_scene == null:
		return null
	if not can_place_build(Game.BuildType.BIG_TOWER, cell):
		return null

	var cells := _big_tower_cells(cell)
	var tower: Tower = big_tower_scene.instantiate()
	tower.grid = self
	tower.cell = cell
	tower.hex_size = hex_size
	tower.cells = cells
	tower.position = _footprint_center(cells)
	for c in cells:
		towers[c] = tower
	add_child(tower)
	return tower


## Construye un aliado (guardia, largo alcance o pirañas) en `cell`.
## Como extienden Tower, se guardan en `towers` (los enemigos los atacan).
func _build_ally_with(scene: PackedScene, cell: Vector2i) -> Ally:
	if scene == null:
		return null
	if not can_place(cell):
		return null

	var ally: Ally = scene.instantiate()
	ally.grid = self
	ally.cell = cell
	ally.hex_size = hex_size
	ally.cells = [cell]
	ally.position = hex_to_pixel(cell.x, cell.y)
	towers[cell] = ally
	add_child(ally)
	return ally


## Construye un guardia en `cell`.
func build_guardia(cell: Vector2i) -> Ally:
	return _build_ally_with(guardia_scene, cell)


## Construye un aliado de largo alcance en `cell`.
func build_long_range(cell: Vector2i) -> Ally:
	return _build_ally_with(long_range_scene, cell)


## Construye unas pirañas en `cell` (ocupa 1 hex pero 4 slots).
func build_piranas(cell: Vector2i) -> Ally:
	return _build_ally_with(piranas_scene, cell)


## Construye un edificio base en `anchor`.
func build_building(anchor: Vector2i) -> Building:
	return _build_building_with(building_scene, anchor)


## Construye una guardería en `anchor`.
func build_guarderia(anchor: Vector2i) -> Building:
	return _build_building_with(guarderia_scene, anchor)


## Construye una cultivadora en `anchor`.
func build_cultivadora(anchor: Vector2i) -> Building:
	return _build_building_with(cultivadora_scene, anchor)


## Edificio genérico (3 hexágonos) anclado en `anchor`. El nodo queda centrado en
## el centro geométrico del footprint y se anota bajo sus 3 celdas.
func _build_building_with(scene: PackedScene, anchor: Vector2i) -> Building:
	if scene == null:
		return null
	var cells := _building_cells(anchor)
	for c in cells:
		if not can_place(c):
			return null

	var building: Building = scene.instantiate()
	building.grid = self
	building.cell = anchor
	building.hex_size = hex_size
	building.cells = cells
	building.position = _footprint_center(cells)
	for c in cells:
		buildings[c] = building
	add_child(building)
	return building


## Saca un edificio del diccionario (la llama Building.die al destruirse).
func remove_building(building: Building) -> void:
	for c in building.cells:
		buildings.erase(c)


## Las celdas (axiales) que ocupa un edificio base anclado en `anchor`.
func _building_cells(anchor: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in BUILDING_FOOTPRINT:
		out.append(anchor + d)
	return out


## Saca una torre del diccionario (la llama Tower.die al destruirse). Borra todas
## las celdas que ocupa (una torre normal ocupa 1, el cañón 4).
func remove_tower(tower: Tower) -> void:
	for c in tower.cells:
		towers.erase(c)


## Las celdas (axiales) que ocupa un cañón anclado en `anchor`.
func _big_tower_cells(anchor: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in BIG_TOWER_FOOTPRINT:
		out.append(anchor + d)
	return out


## Centro en píxeles de un grupo de celdas (para ubicar el cañón sobre su 2x2).
func _footprint_center(cells: Array[Vector2i]) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	for c in cells:
		sum += hex_to_pixel(c.x, c.y)
	return sum / float(cells.size())


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

	# Vista previa: celda(s) destino (verde/rojo) + fantasma siguiendo el mouse.
	if preview_texture != null:
		var cc: Color = Color(0.2, 0.9, 0.3, 0.5) if preview_valid else Color(0.9, 0.2, 0.2, 0.5)
		# El cañón pinta su footprint 2x2, el edificio sus 3 celdas; el resto una sola.
		if preview_type == Game.BuildType.BIG_TOWER:
			for c in _big_tower_cells(preview_cell):
				_draw_hexagon(hex_to_pixel(c.x, c.y), cc)
		elif _is_building(preview_type):
			for c in _building_cells(preview_cell):
				_draw_hexagon(hex_to_pixel(c.x, c.y), cc)
		else:
			_draw_hexagon(hex_to_pixel(preview_cell.x, preview_cell.y), cc)

		var s: float = hex_size * 1.8
		if preview_type == Game.BuildType.BIG_TOWER:
			s = hex_size * 4.5
		elif _is_building(preview_type):
			s = hex_size * 3.6
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
