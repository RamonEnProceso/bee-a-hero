class_name Bird
extends Enemy

## Pájaro: entra volando, picotea la torre más lejana del centro (o sus paredes)
## y se va. Hace poco daño: es para obligarte a cercar tus torres con paredes.

enum State { FLY_IN, PECK, FLY_OUT }

@export var peck_interval: float = 1.0
## Cuántos picotazos da antes de irse.
@export var max_pecks: int = 3
## Distancia a la que empieza a picotear.
@export var peck_range: float = 22.0

var _state: int = State.FLY_IN
var _target_tower: Tower
var _current_target = null  # pared o torre (ambas tienen take_damage)
var _peck_cooldown: float = 0.0
var _pecks: int = 0
var _exit_dir: Vector2 = Vector2.RIGHT


func _texture() -> Texture2D:
	return Art.bird()


func _ready() -> void:
	super()
	_pick_target()


## Elige la torre más lejana del centro; si no hay torres, se va directo.
func _pick_target() -> void:
	_target_tower = _furthest_tower()
	if _target_tower == null:
		_state = State.FLY_OUT
		_exit_dir = _away_from_center()
		return
	# Primero las paredes que rodean a la torre (para poder picotearla).
	_current_target = _wall_adjacent_to(_target_tower)
	if _current_target == null:
		_current_target = _target_tower


func _process(delta: float) -> void:
	if dead:
		return
	_apply_knockback(delta)
	match _state:
		State.FLY_IN:
			if not is_instance_valid(_current_target):
				_pick_target()
				if _state == State.FLY_OUT or _current_target == null:
					return
			_fly_toward(_current_target.global_position, delta)
			if global_position.distance_to(_current_target.global_position) <= peck_range:
				_state = State.PECK
				_peck_cooldown = 0.0
		State.PECK:
			_peck(delta)
		State.FLY_OUT:
			global_position += _exit_dir * speed * delta
			rotation = _exit_dir.angle()
			if global_position.length() > (hex_grid.grid_radius + 3.0) * hex_grid.hex_size * 1.6:
				leave()


func _fly_toward(pos: Vector2, delta: float) -> void:
	var dir: Vector2 = (pos - global_position).normalized()
	global_position += dir * speed * delta
	rotation = dir.angle()


## Picotea la pared/torre actual; si se rompe, pasa a la siguiente o se va.
func _peck(delta: float) -> void:
	if not is_instance_valid(_current_target):
		_current_target = _wall_adjacent_to(_target_tower)
		if _current_target == null and is_instance_valid(_target_tower):
			_current_target = _target_tower
		if _current_target == null:
			leave()
			return

	_peck_cooldown -= delta
	if _peck_cooldown <= 0.0:
		_current_target.take_damage(damage, self)
		_pecks += 1
		_peck_cooldown = peck_interval
		if _pecks >= max_pecks:
			_state = State.FLY_OUT
			_exit_dir = _away_from_center()


## Dirección desde el centro hacia afuera (por la posición actual).
func _away_from_center() -> Vector2:
	var dir: Vector2 = (global_position - hex_grid.world_position_of(0, 0)).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	return dir


## Torre con mayor distancia al centro.
func _furthest_tower() -> Tower:
	var best: Tower = null
	var best_dist := -1
	for cell in hex_grid.towers:
		var d: int = hex_grid.cube_radius(cell.x, cell.y)
		if d > best_dist:
			best_dist = d
			best = hex_grid.towers[cell]
	return best


## Una pared vecina a la torre (la primera que encuentra), o null.
func _wall_adjacent_to(tower: Tower) -> Wall:
	for nb in hex_grid.get_neighbors(tower.cell):
		if hex_grid.walls.has(nb):
			return hex_grid.walls[nb]
	return null
