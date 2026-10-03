class_name CatPaw
extends Enemy

## Pata de gato: se lleva una torre que esté descubierta (sin paredes al lado).
## Para proteger una torre, rodeala de paredes.

@export var steal_range: float = 20.0

var _target_tower: Tower


func _texture() -> Texture2D:
	return Art.cat_paw()


func _ready() -> void:
	super()
	_target_tower = _uncovered_tower()
	if _target_tower == null:
		# No hay torre descubierta: se va sin hacer nada.
		leave()


func _process(delta: float) -> void:
	if dead:
		return
	_apply_knockback(delta)

	if _target_tower == null or not is_instance_valid(_target_tower):
		leave()
		return

	var dir: Vector2 = (_target_tower.global_position - global_position).normalized()
	global_position += dir * speed * delta
	rotation = dir.angle()

	if global_position.distance_to(_target_tower.global_position) <= steal_range:
		_steal()


## Roba la torre y se va.
func _steal() -> void:
	_target_tower.die()
	leave()


## Torre descubierta más cercana (sin ninguna pared vecina), o null.
func _uncovered_tower() -> Tower:
	var best: Tower = null
	var best_dist := INF
	for cell in hex_grid.towers:
		var tower: Tower = hex_grid.towers[cell]
		if _has_adjacent_wall(cell):
			continue
		var d: float = global_position.distance_to(tower.global_position)
		if d < best_dist:
			best_dist = d
			best = tower
	return best


func _has_adjacent_wall(cell: Vector2i) -> bool:
	for nb in hex_grid.get_neighbors(cell):
		if hex_grid.walls.has(nb):
			return true
	return false
