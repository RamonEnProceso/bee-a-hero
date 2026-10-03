class_name HexGrid
extends Node2D

## Distancia del centro de cada hexágono a sus vértices, en píxeles.
@export var hex_size: float = 32.0
## Cuántos "anillos" de hexágonos se dibujan alrededor del centro (0,0).
@export var grid_radius: int = 6

# Colores placeholder (sin arte todavía, solo hexágonos de color).
@export var fill_color: Color = Color(0.95, 0.72, 0.20)
@export var outline_color: Color = Color(0.55, 0.38, 0.10)
@export var hover_color: Color = Color(1.0, 0.92, 0.45)

# Celda sobre la que está el mouse en este instante.
var hovered: Vector2i = Vector2i.ZERO


func _ready() -> void:
	# Centramos el panal en la pantalla para que la celda (0,0) quede en el medio.
	position = get_viewport_rect().size / 2.0


func _process(_delta: float) -> void:
	# Convertimos la posición global del mouse a coordenadas locales de la grilla
	# y buscamos qué hexágono contiene ese punto.
	hovered = pixel_to_hex(to_local(get_global_mouse_position()))
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Al hacer click izquierdo, imprimimos la celda clickeada (útil para debug).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell: Vector2i = pixel_to_hex(to_local(get_global_mouse_position()))
		print("Celda clickeada: (q=", cell.x, ", r=", cell.y, ")")


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
	# Coordenadas cúbicas fraccionarias.
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

	# Corregimos la componente con mayor error para que q + r + s siga valiendo 0.
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


## Celdas del anillo exterior (radio == grid_radius), para spawnear enemigos en el borde.
func get_ring_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for q in range(-grid_radius, grid_radius + 1):
		var r_min: int = maxi(-grid_radius, -q - grid_radius)
		var r_max: int = mini(grid_radius, -q + grid_radius)
		for r in range(r_min, r_max + 1):
			# El "radio cúbico" de una celda es max(|q|, |r|, |q+r|).
			var radius: int = maxi(absi(q), maxi(absi(r), absi(q + r)))
			if radius == grid_radius:
				cells.append(Vector2i(q, r))
	return cells


# ---------------------------------------------------------------------------
# Dibujo.
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Recorremos todas las celdas de un panal de radio `grid_radius`.
	for q in range(-grid_radius, grid_radius + 1):
		# En un panal hexagonal, para cada columna q, r va entre estos límites.
		var r_min: int = maxi(-grid_radius, -q - grid_radius)
		var r_max: int = mini(grid_radius, -q + grid_radius)
		for r in range(r_min, r_max + 1):
			var cell: Vector2i = Vector2i(q, r)
			var center: Vector2 = hex_to_pixel(q, r)
			var color: Color = hover_color if cell == hovered else fill_color
			_draw_hexagon(center, color)


## Dibuja un solo hexágono (punto-arriba) relleno y con contorno.
func _draw_hexagon(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 6:
		# Punto-arriba: los vértices están a -30°, 30°, 90°, 150°, 210° y 270°.
		var angle: float = deg_to_rad(60.0 * i - 30.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * hex_size)

	draw_colored_polygon(points, color)

	# Contorno: polilínea cerrada (repetimos el primer punto al final).
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, outline_color, 2.0, true)
