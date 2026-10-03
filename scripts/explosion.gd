class_name Explosion
extends Node2D

## Mini explosión al morir un enemigo: un círculo que se expande y se desvanece.


@export var max_radius: float = 16.0
@export var lifetime: float = 0.28
@export var color: Color = Color(1.0, 0.6, 0.15)

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= lifetime:
		queue_free()


func _draw() -> void:
	var k: float = clampf(_t / lifetime, 0.0, 1.0)
	var r: float = max_radius * k
	var a: float = 1.0 - k
	draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, a * 0.5))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(color.r, color.g, color.b, a), 2.0, true)
