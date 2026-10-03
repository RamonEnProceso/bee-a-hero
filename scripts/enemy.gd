class_name Enemy
extends Node2D

@export var speed: float = 60.0
@export var damage: int = 1
@export var wall_damage: int = 1
@export var attack_interval: float = 0.6
@export var body_color: Color = Color(0.85, 0.15, 0.15)
@export var outline_color: Color = Color(0.4, 0.05, 0.05)

## A quién persigue (siempre la reina por ahora).
var target: Queen
## Referencia a la grilla para detectar paredes en el camino.
var hex_grid: HexGrid
var dead: bool = false

# Cooldown entre golpes a una pared.
var attack_cooldown: float = 0.0


func _process(delta: float) -> void:
	if dead or target == null:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	# Dirección en línea recta hacia la reina.
	var dir: Vector2 = (target.global_position - global_position).normalized()

	# Si hay una pared justo delante, nos detenemos y la atacamos.
	if hex_grid != null:
		var lookahead: Vector2 = global_position + dir * (hex_grid.hex_size * 0.5)
		var wall: Wall = hex_grid.wall_at(hex_grid.cell_at_world(lookahead))
		if wall != null:
			rotation = dir.angle()
			if attack_cooldown <= 0.0:
				wall.take_damage(wall_damage)
				attack_cooldown = attack_interval
			return

	# Sin obstáculos: avanzamos y rotamos para "mirar" hacia donde vamos.
	global_position += dir * speed * delta
	rotation = dir.angle()

	# Si llegó a la reina, le hace daño y desaparece.
	if global_position.distance_to(target.global_position) < 12.0:
		_hit_queen()


func _hit_queen() -> void:
	dead = true
	target.take_damage(damage)
	queue_free()


func _draw() -> void:
	# Placeholder visual: triángulo rojo (la avispa) apuntando a +X, rota con el nodo.
	var r: float = 8.0
	var p0 := Vector2(r * 1.6, 0.0)
	var p1 := Vector2(-r, r)
	var p2 := Vector2(-r, -r)
	draw_colored_polygon(PackedVector2Array([p0, p1, p2]), body_color)
	draw_polyline(PackedVector2Array([p0, p1, p2, p0]), outline_color, 1.5, true)
