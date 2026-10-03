class_name Smoke
extends Node2D

## Insecticida: humo que se esparce desde el borde. No se puede atacar, solo se
## contiene con paredes. Daña las torres abejas y se disipa con el tiempo.

@export var spread_interval: float = 1.5
@export var damage_interval: float = 1.0
@export var damage: int = 1
## Cuántos anillos se expande como máximo.
@export var max_rings: int = 5
@export var lifetime: float = 20.0

var grid: HexGrid
var origin_cell: Vector2i = Vector2i.ZERO

var _covered: Dictionary = {}
var _frontier: Array[Vector2i] = []
var _spread_timer: float = 0.0
var _damage_timer: float = 0.0
var _rings: int = 0


func _ready() -> void:
	_covered[origin_cell] = true
	_frontier.append(origin_cell)
	_spread_timer = spread_interval
	_damage_timer = damage_interval
	queue_redraw()


func _process(delta: float) -> void:
	lifetime -= delta

	# Expansión por anillos; las paredes la bloquean.
	_spread_timer -= delta
	if _spread_timer <= 0.0 and _rings < max_rings:
		_expand()
		_spread_timer = spread_interval

	# Daño a las torres dentro del humo.
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_towers()
		_damage_timer = damage_interval

	# Se desvanece y desaparece al final de su vida.
	if lifetime < 1.5:
		modulate.a = clampf(lifetime / 1.5, 0.0, 1.0)
	if lifetime <= 0.0:
		queue_free()


## Expande el humo un anillo (no cruza paredes).
func _expand() -> void:
	var next: Array[Vector2i] = []
	for cell in _frontier:
		for nb in grid.get_neighbors(cell):
			if _covered.has(nb):
				continue
			if grid.walls.has(nb):
				continue  # la pared contiene el humo
			_covered[nb] = true
			next.append(nb)
	_frontier = next
	_rings += 1
	queue_redraw()


## Daña a cada torre cuya celda esté cubierta por el humo.
func _damage_towers() -> void:
	# Iteramos una copia de las claves: si una torre muere, se borra de `grid.towers`.
	var seen: Dictionary = {}
	var cells: Array = grid.towers.keys()
	for cell in cells:
		if _covered.has(cell) and grid.towers.has(cell):
			var tower: Tower = grid.towers[cell]
			if seen.has(tower):
				continue
			seen[tower] = true
			tower.take_damage(damage)


func _draw() -> void:
	for cell in _covered:
		var pos: Vector2 = grid.hex_to_pixel(cell.x, cell.y)
		draw_circle(pos, grid.hex_size * 0.85, Color(0.4, 0.8, 0.5, 0.18))
