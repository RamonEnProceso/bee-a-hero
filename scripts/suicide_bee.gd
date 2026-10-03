class_name SuicideBee
extends Node2D

## Abeja suicida: espera en un anillo alrededor de la reina mirando hacia afuera.
## Cuando un enemigo la toca, sale volando hacia él y explota con daño en área.

## Velocidad de vuelo una vez activada.
@export var speed: float = 260.0
## Daño de la explosión (se aplica a todo el área).
@export var damage: int = 3
## Radio del área de la explosión.
@export var blast_radius: float = 60.0
## Distancia a la que un enemigo "la toca" y la activa.
@export var trigger_radius: float = 34.0

## Hacia dónde mira (la setea main.gd al colocarla: contraria al centro).
var direction: Vector2 = Vector2.UP
var _target: Enemy = null  # enemigo al que persigue tras activarse
var _activated: bool = false
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = Art.suicide_bee()
	rotation = direction.angle()


func _process(delta: float) -> void:
	if _activated:
		# En vuelo: persigue al objetivo; si ya no existe, explota de todas formas.
		if _target != null and is_instance_valid(_target) and not _target.dead:
			direction = (_target.global_position - global_position).normalized()
			rotation = direction.angle()
			global_position += direction * speed * delta
			if global_position.distance_to(_target.global_position) <= 12.0:
				_explode()
		else:
			_explode()
		return

	# Esperando: se activa con el primer enemigo que la toca.
	var e: Enemy = _nearest_enemy_in(trigger_radius)
	if e != null:
		_target = e
		_activated = true


## Enemigo más cercano dentro de `radius`, o null.
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


## Explota: daña a todos los enemigos vivos en el área y desaparece.
func _explode() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null or e.dead:
			continue
		if global_position.distance_to(e.global_position) <= blast_radius:
			e.take_damage(damage)
	queue_free()
