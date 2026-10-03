class_name Enemy
extends Node2D

## La avispa enemiga: va en línea recta hacia la reina, atacando estructuras en el camino.
## Nunca ataca a la abeja protagonista (es invulnerable).

@export var max_health: int = 3
@export var speed: float = 60.0
@export var damage: int = 1
@export var structure_damage: int = 1
@export var attack_interval: float = 0.6
## Material que suelta al ser destruida.
@export var material_reward: int = 5

## Se emite al morir (para que el spawner cuente las bajas de la oleada).
signal died

## A quién persigue (siempre la reina).
var target: Queen
## Referencia a la grilla para detectar estructuras en el camino.
var hex_grid: HexGrid
var dead: bool = false

var health: int
# Cooldown entre golpes a una estructura.
var attack_cooldown: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	sprite.texture = Art.enemy()


func _process(delta: float) -> void:
	if dead or target == null:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	# Dirección en línea recta hacia la reina.
	var dir: Vector2 = (target.global_position - global_position).normalized()

	# Si hay una estructura (pared o torre) justo delante, nos detenemos y la atacamos.
	if hex_grid != null:
		var lookahead: Vector2 = global_position + dir * (hex_grid.hex_size * 0.5)
		var structure = hex_grid.structure_at(hex_grid.cell_at_world(lookahead))
		if structure != null:
			rotation = dir.angle()
			if attack_cooldown <= 0.0:
				structure.take_damage(structure_damage)
				attack_cooldown = attack_interval
			return

	# Sin obstáculos: avanzamos y rotamos para "mirar" hacia donde vamos.
	global_position += dir * speed * delta
	rotation = dir.angle()

	# Si llegó a la reina, le hace daño y desaparece.
	if global_position.distance_to(target.global_position) < 12.0:
		_hit_queen()


## Recibe daño de los proyectiles.
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		die(true)


## `reward` = true si la mató una torre/abeja (suelta material); false si llegó a la reina.
func die(reward: bool = false) -> void:
	if dead:
		return
	dead = true
	died.emit()
	if reward:
		Game.gain(material_reward)
	queue_free()


func _hit_queen() -> void:
	target.take_damage(damage)
	die(false)
