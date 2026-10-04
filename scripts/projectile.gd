class_name Projectile
extends Node2D

## Proyectil: hace homing hacia un enemigo (torre) o viaja en línea recta (disparo del jugador).

@export var speed: float = 220.0
@export var hit_radius: float = 10.0
## Tiempo máximo de vida, para que no queden volando para siempre.
@export var lifetime: float = 2.5

## Si está seteado, el proyectil hace homing hacia este enemigo.
var target: Enemy
## Si target == null, el proyectil viaja en esta dirección (disparo del jugador).
var direction: Vector2 = Vector2.ZERO
var damage: int = 1
## Escala del sprite (el PNG de la miel viene a 64px, hay que achicarlo).
@export var sprite_scale: float = 0.25
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = Art.projectile()
	sprite.scale = Vector2(sprite_scale, sprite_scale)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Si tenía objetivo y ya no existe, se descarta.
	if target != null and (not is_instance_valid(target) or target.dead):
		queue_free()
		return

	var dir: Vector2
	if target != null:
		dir = (target.global_position - global_position).normalized()
	else:
		dir = direction

	global_position += dir * speed * delta
	# La gota de miel dibuja con la punta hacia abajo; la rotamos -90° para que la
	# punta apunte en la dirección de viaje.
	rotation = dir.angle() - PI / 2.0

	if target != null:
		# Homing: al alcanzar el objetivo, le hace daño y lo empuja.
		if global_position.distance_to(target.global_position) <= hit_radius:
			target.take_damage(damage, dir)
			queue_free()
	else:
		# Línea recta: daña al primer enemigo que toque y lo empuja.
		for node in get_tree().get_nodes_in_group("enemies"):
			var e := node as Enemy
			if e != null and global_position.distance_to(e.global_position) <= hit_radius + 8.0:
				e.take_damage(damage, direction)
				queue_free()
				return
