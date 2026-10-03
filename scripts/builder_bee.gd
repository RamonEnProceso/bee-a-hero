class_name BuilderBee
extends Node2D

## La abeja protagonista (constructora): se mueve por el panal, la cámara la sigue
## y dispara con ESPACIO hacia el mouse. Es invulnerable (no recibe daño).

@export var speed: float = 160.0
@export var projectile_scene: PackedScene
@export var fire_interval: float = 0.3
@export var damage: int = 2

## Referencia a la grilla (para mantener a la abeja dentro del panal).
var grid: HexGrid
var fire_cooldown: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# La cámara es hija nuestra: se mueve con la abeja automáticamente.
	$Camera2D.make_current()
	add_to_group("player")
	sprite.texture = Art.bee()


func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)

	# Movimiento WASD + flechas (Node2D simple, no choca con nada).
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0

	position += dir.normalized() * speed * delta

	# Disparo: espacio dispara hacia donde apunta el mouse.
	if Input.is_physical_key_pressed(KEY_SPACE) and fire_cooldown <= 0.0:
		_shoot()
		fire_cooldown = fire_interval

	# La mantenemos cerca del panal para que no se pierda por la pantalla.
	if grid != null:
		var max_dist: float = (grid.grid_radius + 2.0) * grid.hex_size * 1.5
		if position.length() > max_dist:
			position = position.normalized() * max_dist


func _shoot() -> void:
	if projectile_scene == null:
		return
	var p: Projectile = projectile_scene.instantiate()
	p.target = null
	p.damage = damage
	p.direction = (get_global_mouse_position() - global_position).normalized()
	p.global_position = global_position
	get_parent().add_child(p)
