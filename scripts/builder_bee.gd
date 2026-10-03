class_name BuilderBee
extends Node2D

## La abeja protagonista (constructora): se mueve por el panal, la cámara la sigue
## y dispara con ESPACIO hacia el mouse. Es invulnerable (no recibe daño).

@export var speed: float = 160.0
@export var projectile_scene: PackedScene
@export var fire_interval: float = 0.3
@export var damage: int = 2

## Escala del sprite (los PNG vienen a 512px, hay que achicarlos).
@export var sprite_scale: float = 0.13
## Máxima inclinación al moverse a los costados (radianes).
@export var lean_angle: float = 0.12
## Segundos por frame del aleteo (más chico = alas más rápidas).
@export var flap_interval: float = 0.1
## Amplitud del vaivén vertical (px) para el efecto de vuelo.
@export var bob_amplitude: float = 4.0
## Velocidad del vaivén vertical (radianes/segundo).
@export var bob_speed: float = 8.0

## Los dos frames del aleteo (la abeja mira a la derecha en ambos).
const FLAP_TEXTURES := [
	preload("res://textures/AbejaLaburante00.png"),
	preload("res://textures/AbejaLaburante01.png"),
]

## Referencia a la grilla (para mantener a la abeja dentro del panal).
var grid: HexGrid
var fire_cooldown: float = 0.0

# Hacia dónde mira (1 = derecha, -1 = izquierda).
var _face: int = 1
# Estado del aleteo y del vaivén.
var _flap_timer: float = 0.0
var _flap_frame: int = 0
var _bob_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# La cámara es hija nuestra: se mueve con la abeja automáticamente.
	$Camera2D.make_current()
	add_to_group("player")
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.texture = FLAP_TEXTURES[0]


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

	_animate(delta, dir)


## Aleteo (bucle 00/01) + giro a izquierda/derecha + inclinación + vaivén vertical.
func _animate(delta: float, dir: Vector2) -> void:
	# Aleteo: alterna los dos frames en bucle.
	_flap_timer += delta
	if _flap_timer >= flap_interval:
		_flap_timer = 0.0
		_flap_frame = 1 - _flap_frame
		sprite.texture = FLAP_TEXTURES[_flap_frame]

	# Giro: al moverse a la izquierda el sprite mira a la izquierda (flip_h).
	if dir.x < 0.0:
		_face = -1
	elif dir.x > 0.0:
		_face = 1
	sprite.flip_h = _face < 0

	# Inclinación mínima hacia donde se mueve (vuelve a 0 al parar).
	var target_lean: float = dir.x * lean_angle
	sprite.rotation = lerp_angle(sprite.rotation, target_lean, minf(1.0, 12.0 * delta))

	# Vaivén vertical: siempre sube y baja para simular el vuelo.
	_bob_time += delta
	sprite.position.y = sin(_bob_time * bob_speed) * bob_amplitude


func _shoot() -> void:
	if projectile_scene == null:
		return
	var p: Projectile = projectile_scene.instantiate()
	p.target = null
	p.damage = damage
	p.direction = (get_global_mouse_position() - global_position).normalized()
	p.global_position = global_position
	get_parent().add_child(p)
