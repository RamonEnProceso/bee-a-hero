class_name SpiralWasp
extends Enemy

## Avispa torbellino: en vez de ir en línea recta, gira en espiral desde el borde
## hacia el centro (la reina). Vuela por encima de las estructuras.

## Velocidad angular del giro (radianes/segundo). Más alto = vueltas más cerradas.
@export var angular_speed: float = 2.4
## Cuánto se achica el radio por segundo (px/s). Más alto = llega más rápido.
@export var inward_speed: float = 70.0
## A qué distancia de la reina la alcanza (px).
@export var hit_distance: float = 24.0

var _angle: float = 0.0
var _radius: float = 0.0

## Los dos frames del aleteo de la mosca/torbellino.
const MOSCA_TEXTURES := [
	preload("res://textures/mosca_00.png"),
	preload("res://textures/mosca_01.png"),
]


func _textures() -> Array:
	return MOSCA_TEXTURES


func _ready() -> void:
	super()
	# Arrancamos girando desde la posición de spawn (borde del panal).
	var center: Vector2 = target.global_position
	var offset: Vector2 = global_position - center
	_radius = maxf(offset.length(), 1.0)
	_angle = offset.angle()


func _process(delta: float) -> void:
	if dead or target == null:
		return
	_animate_flap(delta)
	# Gira y achica el radio: espiral hacia el centro.
	_angle += angular_speed * delta
	_radius = maxf(0.0, _radius - inward_speed * delta)
	var center: Vector2 = target.global_position
	global_position = center + Vector2(cos(_angle), sin(_angle)) * _radius
	# Mira hacia la tangente del giro (la dirección de avance).
	rotation = _angle + PI / 2.0 + rotation_offset
	if _radius <= hit_distance:
		_hit_queen()
