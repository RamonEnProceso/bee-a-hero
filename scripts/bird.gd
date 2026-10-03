class_name Bird
extends Enemy

## Pájaro: entra volando hacia la reina, no ataca nada, y se vuelve por donde vino.
## Es una distracción que te obliga a mirar el cielo (y a dispararle antes de que se vaya).

enum State { FLY_IN, FLY_OUT }

## A qué distancia de la reina da la vuelta para volver.
@export var turn_radius: float = 90.0

var _state: int = State.FLY_IN
# Dirección de salida: desde el centro hacia donde apareció (por donde vino).
var _out_dir: Vector2 = Vector2.RIGHT


func _texture() -> Texture2D:
	return Art.bird()


func _ready() -> void:
	super()
	# Por dónde entró: su spawn está en el borde, así que "centro -> spawn" es su salida.
	var center: Vector2 = hex_grid.world_position_of(0, 0)
	_out_dir = (global_position - center).normalized()
	if _out_dir == Vector2.ZERO:
		_out_dir = Vector2.RIGHT


func _process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	_apply_knockback(delta)
	match _state:
		State.FLY_IN:
			# Vuela hacia la reina hasta acercarse, y ahí da la vuelta.
			if global_position.distance_to(target.global_position) <= turn_radius:
				_state = State.FLY_OUT
			else:
				_fly_toward(target.global_position, delta)
		State.FLY_OUT:
			# Se va hacia donde vino; desaparece al salir del panal.
			global_position += _out_dir * speed * delta
			rotation = _out_dir.angle()
			if global_position.length() > (hex_grid.grid_radius + 3.0) * hex_grid.hex_size * 1.6:
				leave()


func _fly_toward(pos: Vector2, delta: float) -> void:
	var dir: Vector2 = (pos - global_position).normalized()
	global_position += dir * speed * delta
	rotation = dir.angle()
