class_name Enemy
extends Node2D

## Base de los enemigos: van en línea recta hacia la reina, atacando estructuras
## en el camino. Los subtipos (avispa grande, avispón, torbellino, tiradora, gato,
## oso) heredan y cambian textura, vida, velocidad y comportamiento.

@export var max_health: int = 3
@export var speed: float = 100.0
## Daño que le hace a la reina al llegar.
@export var damage: int = 1
## Daño que le hace a las estructuras (paredes/torres) por golpe.
@export var structure_damage: int = 1
@export var attack_interval: float = 0.6
## Material que suelta al ser destruido.
@export var material_reward: int = 3
## Escena de la gota de miel que suelta al morir (la abeja la recolecta).
@export var pickup_scene: PackedScene
## Empuje que recibe por cada proyectil que le pega (px de velocidad).
@export var knockback_force: float = 24.0
## Qué tan resistente es al empuje: 0 = empuje normal, 1 = no retrocede.
@export var knockback_resistance: float = 0.0
## Cuán rápido se frena el empuje (px/s²).
@export var knockback_decay: float = 160.0
## Escala del sprite (los jefes son más grandes).
@export var body_scale: float = 1.0

## Se emite al morir (para que el spawner cuente las bajas de la oleada).
signal died

## Escena de la mini explosión que aparece al morir.
const EXPLOSION_SCENE: PackedScene = preload("res://scenes/Explosion.tscn")

## A quién persigue (siempre la reina).
var target: Queen
## Referencia a la grilla para detectar estructuras en el camino.
var hex_grid: HexGrid
var dead: bool = false

var health: int
# Cooldown entre golpes a una estructura.
var attack_cooldown: float = 0.0
# Velocidad extra que empuja al enemigo al recibir daño.
var _knockback: Vector2 = Vector2.ZERO
var _hit_tween: Tween
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	sprite.texture = _texture()
	sprite.scale = Vector2(body_scale, body_scale)


## Textura de este enemigo (cada subtipo devuelve la suya).
func _texture() -> Texture2D:
	return Art.enemy()


func _process(delta: float) -> void:
	if dead or target == null:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	_apply_knockback(delta)

	# Dirección en línea recta hacia la reina.
	var dir: Vector2 = (target.global_position - global_position).normalized()

	# Si hay una estructura (pared o torre) justo delante, nos detenemos y la atacamos.
	# Revisamos la celda de adelante y también la nuestra (por si ya estamos encima).
	if hex_grid != null:
		var lookahead: Vector2 = global_position + dir * (hex_grid.hex_size * 0.5)
		var structure = hex_grid.structure_at(hex_grid.cell_at_world(lookahead))
		if structure == null:
			structure = hex_grid.structure_at(hex_grid.cell_at_world(global_position))
		if structure != null:
			rotation = dir.angle()
			if attack_cooldown <= 0.0:
				structure.take_damage(structure_damage, self)
				attack_cooldown = attack_interval
			return

	# Sin obstáculos: avanzamos y rotamos para "mirar" hacia donde vamos.
	global_position += dir * speed * delta
	rotation = dir.angle()

	# Si llegó a la reina, le hace daño y desaparece.
	if global_position.distance_to(target.global_position) < 12.0:
		_hit_queen()


## Aplica el empuje de los proyectiles (y lo va frenando).
func _apply_knockback(delta: float) -> void:
	if _knockback.length_squared() < 0.01:
		_knockback = Vector2.ZERO
		return
	global_position += _knockback * delta
	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_decay * delta)


## Recibe daño de los proyectiles. `hit_dir` empuja al enemigo en esa dirección.
func take_damage(amount: int, hit_dir: Vector2 = Vector2.ZERO) -> void:
	health = maxi(0, health - amount)
	if hit_dir != Vector2.ZERO:
		_knockback = hit_dir * knockback_force * (1.0 - knockback_resistance)
	_hit_flash()
	if health <= 0:
		die(true)


## Al recibir daño: se pone blanco y se achica un poco, y vuelve a la normalidad.
func _hit_flash() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	# Un modulate alto satura los canales de color y se ve blanco.
	sprite.modulate = Color(6.0, 6.0, 6.0, 1.0)
	sprite.scale = Vector2(body_scale, body_scale) * 0.9
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "scale", Vector2(body_scale, body_scale), 0.1)
	_hit_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.1)


## `reward` = true si la mató una torre/abeja (suelta material); false si llegó a la reina.
func die(reward: bool = false) -> void:
	if dead:
		return
	dead = true
	died.emit()
	if reward:
		_spawn_explosion()
		_drop_pickup()
	queue_free()


## Mini explosión al morir (feedback visual).
func _spawn_explosion() -> void:
	var e: Explosion = EXPLOSION_SCENE.instantiate()
	get_parent().add_child(e)
	e.global_position = global_position
	e.scale = Vector2(body_scale, body_scale)


## El enemigo se retira del escenario sin soltar material (gato/oso).
func leave() -> void:
	die(false)


## Suelta una gota de miel que la abeja protagonista recolecta al acercarse.
func _drop_pickup() -> void:
	if pickup_scene == null:
		return
	var p: Pickup = pickup_scene.instantiate()
	p.value = material_reward
	get_parent().add_child(p)
	p.global_position = global_position


func _hit_queen() -> void:
	target.take_damage(damage)
	die(false)
