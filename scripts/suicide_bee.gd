class_name SuicideBee
extends Node2D

## Abeja suicida: espera en un anillo alrededor de la reina mirando hacia afuera.
## Cuando un enemigo la toca, sale volando hacia él y explota con daño en área.
## Se anima con dos sprites de aleteo y un vaivén vertical de vuelo, más lento
## y más corto que el de la reina y la constructora.

@export var speed: float = 260.0
@export var damage: int = 3
@export var blast_radius: float = 60.0
@export var trigger_radius: float = 34.0

## Escala del sprite (los PNG vienen a 512px, hay que achicarlos).
@export var sprite_scale: float = 0.112
## Segundos por frame del aleteo (más chico = alas más rápidas).
@export var flap_interval: float = 0.1
## Amplitud del vaivén vertical (px). Más corta que la reina (4.0).
@export var bob_amplitude: float = 2.0
## Velocidad del vaivén vertical (radianes/segundo). Más lenta que la reina (8.0).
@export var bob_speed: float = 4.0

## Los dos frames del aleteo. La textura mira al sur (hacia abajo).
const FLAP_TEXTURES := [
	preload("res://textures/AbejaSuicida00.png"),
	preload("res://textures/AbejaSuicida01.png"),
]

## La textura apunta hacia abajo por defecto (+Y), así que para apuntar hacia
## `direction` hay que restarle este ángulo al cálculo normal de `.angle()`.
const SOUTH_OFFSET := PI / 2.0

var direction: Vector2 = Vector2.UP
var _target: Enemy = null
var _activated: bool = false

# Estado del aleteo y del vaivén.
var _flap_timer: float = 0.0
var _flap_frame: int = 0
var _bob_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.texture = FLAP_TEXTURES[0]
	rotation = direction.angle() - SOUTH_OFFSET


func _process(delta: float) -> void:
	_animate(delta)

	if _activated:
		if _target != null and is_instance_valid(_target) and not _target.dead:
			direction = (_target.global_position - global_position).normalized()
			rotation = direction.angle() - SOUTH_OFFSET
			global_position += direction * speed * delta
			if global_position.distance_to(_target.global_position) <= 12.0:
				_explode()
		else:
			_explode()
		return

	var e: Enemy = _nearest_enemy_in(trigger_radius)
	if e != null:
		_target = e
		_activated = true


## Aleteo (bucle 00/01) + vaivén vertical en pantalla, independiente del giro.
func _animate(delta: float) -> void:
	# Aleteo: alterna los dos frames en bucle.
	_flap_timer += delta
	if _flap_timer >= flap_interval:
		_flap_timer = 0.0
		_flap_frame = 1 - _flap_frame
		sprite.texture = FLAP_TEXTURES[_flap_frame]
	# Vaivén vertical: el nodo gira para mirar hacia afuera, así que contra-rotamos
	# el vaivén para que siempre suba y baje en pantalla (no a lo largo del giro).
	_bob_time += delta
	var bob: float = sin(_bob_time * bob_speed) * bob_amplitude
	sprite.position = Vector2(0.0, bob).rotated(-rotation)


## Devuelve el enemigo más cercano dentro de `radius` (o null si no hay).
func _nearest_enemy_in(radius: float) -> Enemy:
	var best: Enemy = null
	var best_dist: float = radius
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null:
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best


## Explota: daña en área a todos los enemigos dentro del radio y desaparece.
func _explode() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null or e.dead:
			continue
		if global_position.distance_to(e.global_position) <= blast_radius:
			e.take_damage(damage)
	queue_free()
