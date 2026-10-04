class_name Hormiga
extends Enemy

## Hormiga: roba la miel sin recolectar (las gotas Pickup) y, si no la matás,
## huye por el borde por donde llegó. Si la matás antes, recuperás lo robado.

## A qué distancia agarra una gota de miel.
@export var steal_range: float = 20.0
## Cuántas gotas roba antes de huir.
@export var max_steals: int = 2

var _target_pickup: Pickup
var _steals: int = 0
var _stolen_value: int = 0
var _fleeing: bool = false
var _spawn_pos: Vector2

## Los dos frames del aleteo de la hormiga.
const HORMIGA_TEXTURES := [
	preload("res://textures/hormiga_00.png"),
	preload("res://textures/hormiga_01.png"),
]


func _textures() -> Array:
	return HORMIGA_TEXTURES


func _ready() -> void:
	super()
	_spawn_pos = global_position


func _process(delta: float) -> void:
	if dead:
		return
	_animate_flap(delta)
	_apply_knockback(delta)

	# Huyendo: vuelve al borde por donde llegó y desaparece.
	if _fleeing:
		var dir: Vector2 = (_spawn_pos - global_position).normalized()
		global_position += dir * speed * delta
		rotation = dir.angle() + rotation_offset
		if global_position.distance_to(_spawn_pos) <= 20.0:
			leave()
		return

	# Busca miel sin recolectar; si no queda, huye.
	if _target_pickup == null or not is_instance_valid(_target_pickup):
		_target_pickup = _nearest_pickup()
		if _target_pickup == null:
			_fleeing = true
			return

	var dir: Vector2 = (_target_pickup.global_position - global_position).normalized()

	# Rompe paredes en el camino (como la pata de oso).
	var lookahead: Vector2 = global_position + dir * (hex_grid.hex_size * 0.5)
	var wall: Wall = hex_grid.wall_at(hex_grid.cell_at_world(lookahead))
	if wall == null:
		wall = hex_grid.wall_at(hex_grid.cell_at_world(global_position))
	if wall != null:
		rotation = dir.angle() + rotation_offset
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
		if attack_cooldown <= 0.0:
			wall.take_damage(structure_damage, self)
			attack_cooldown = attack_interval
		return

	global_position += dir * speed * delta
	rotation = dir.angle() + rotation_offset

	# Roba la gota al llegar.
	if global_position.distance_to(_target_pickup.global_position) <= steal_range:
		_stolen_value += _target_pickup.value
		_target_pickup.queue_free()
		_target_pickup = null
		_steals += 1
		if _steals >= max_steals:
			_fleeing = true


## Si la matamos, recupera la miel que robó (se suma al botín normal).
func die(reward: bool = false) -> void:
	if dead:
		return
	if reward:
		material_reward += _stolen_value
	super.die(reward)


## Gota de miel más cercana, o null si no queda ninguna.
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
