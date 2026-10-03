class_name BearPaw
extends Enemy

## Pata de oso: rompe paredes y se roba la miel sin recolectar (Pickups).

@export var steal_range: float = 20.0
## Cuántas gotas de miel roba antes de irse.
@export var max_steals: int = 3

var _target_pickup: Pickup
var _steals: int = 0


func _texture() -> Texture2D:
	return Art.bear_paw()


func _process(delta: float) -> void:
	if dead:
		return
	_apply_knockback(delta)

	# Busca miel sin recolectar; si no queda, se va.
	if _target_pickup == null or not is_instance_valid(_target_pickup):
		_target_pickup = _nearest_pickup()
		if _target_pickup == null:
			leave()
			return

	var dir: Vector2 = (_target_pickup.global_position - global_position).normalized()

	# Si hay una pared delante (o debajo), la rompe.
	var lookahead: Vector2 = global_position + dir * (hex_grid.hex_size * 0.5)
	var wall: Wall = hex_grid.wall_at(hex_grid.cell_at_world(lookahead))
	if wall == null:
		wall = hex_grid.wall_at(hex_grid.cell_at_world(global_position))
	if wall != null:
		rotation = dir.angle()
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
		if attack_cooldown <= 0.0:
			wall.take_damage(structure_damage, self)
			attack_cooldown = attack_interval
		return

	# Avanza hacia la gota.
	global_position += dir * speed * delta
	rotation = dir.angle()

	# Al llegar, se roba la miel.
	if global_position.distance_to(_target_pickup.global_position) <= steal_range:
		_target_pickup.queue_free()
		_target_pickup = null
		_steals += 1
		if _steals >= max_steals:
			leave()


## Gota de miel más cercana, o null.
func _nearest_pickup() -> Pickup:
	var best: Pickup = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("pickups"):
		var p := node as Pickup
		if p == null:
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best = p
	return best
