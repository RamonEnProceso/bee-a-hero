class_name Burst
extends Node2D

## Ráfaga de partículas procedimentales: puntitos que salen volando y se apagan.
## Se usa como "pum" al construir y, más grande, al terminar un edificio.

@export var color: Color = Color(1.0, 0.85, 0.4)
@export var count: int = 10
@export var speed: float = 120.0
@export var lifetime: float = 0.5

var _dots: Array[Vector2] = []
var _vels: Array[Vector2] = []
var _t: float = 0.0


func _ready() -> void:
	# Queda por encima de torres/enemigos pero debajo de la abeja protagonista.
	z_index = 15
	for i in count:
		var ang := TAU * float(i) / float(count)
		_dots.append(Vector2.ZERO)
		_vels.append(Vector2(cos(ang), sin(ang)) * speed * randf_range(0.6, 1.3))


func _process(delta: float) -> void:
	_t += delta
	for i in _dots.size():
		_dots[i] += _vels[i] * delta
	queue_redraw()
	if _t >= lifetime:
		queue_free()


func _draw() -> void:
	# Se va desvaneciendo y achicando mientras se aleja del centro.
	var a: float = clampf(1.0 - _t / lifetime, 0.0, 1.0)
	for i in _dots.size():
		draw_circle(_dots[i], 2.5 * a + 0.5, Color(color.r, color.g, color.b, a))
