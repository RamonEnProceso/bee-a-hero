class_name Projectile
extends Node2D

@export var speed: float = 220.0
@export var hit_radius: float = 10.0
@export var body_color: Color = Color(1.0, 0.9, 0.3)

## A quién persigue el proyectil.
var target: Enemy
var damage: int = 1


func _process(delta: float) -> void:
	# Si el objetivo ya no existe, el proyectil se descarta.
	if target == null or not is_instance_valid(target) or target.dead:
		queue_free()
		return

	var dir: Vector2 = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta
	rotation = dir.angle()

	# Al alcanzarlo, le hace daño y desaparece.
	if global_position.distance_to(target.global_position) <= hit_radius:
		target.take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, body_color)
