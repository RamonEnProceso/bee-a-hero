class_name EnemyProjectile
extends Node2D

## Aguijón que dispara la avispa tiradora hacia la reina. Vuela en línea recta
## y se clava (y desaparece) si choca contra una pared o torre.

@export var speed: float = 190.0
@export var hit_radius: float = 14.0
## Tiempo máximo de vida, para que no quede volando para siempre.
@export var lifetime: float = 5.0

## A quién apunta (la reina).
var target: Queen
## Referencia a la grilla para detectar estructuras que bloquean el tiro.
var hex_grid: HexGrid
var damage: int = 1
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = Art.enemy_projectile()


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	var dir: Vector2
	if target != null and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	else:
		dir = Vector2.DOWN

	# Si hay una estructura (pared/torre) justo delante, el aguijón se clava y desaparece.
	if hex_grid != null:
		var lookahead: Vector2 = global_position + dir * (hex_grid.hex_size * 0.5)
		if hex_grid.structure_at(hex_grid.cell_at_world(lookahead)) != null:
			queue_free()
			return

	global_position += dir * speed * delta
	rotation = dir.angle()

	# Al alcanzar a la reina, le hace daño.
	if target != null and is_instance_valid(target) and global_position.distance_to(target.global_position) <= hit_radius:
		target.take_damage(damage)
		queue_free()
