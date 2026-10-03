class_name Tower
extends Node2D

## La "abeja torreta": dispara a los enemigos. También puede ser atacada y destruida.

@export var range_radius: float = 150.0
@export var fire_interval: float = 0.8
@export var damage: int = 2
@export var max_health: int = 4
@export var projectile_scene: PackedScene

var grid: HexGrid
var cell: Vector2i
var hex_size: float = 32.0

var health: int
var fire_cooldown: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	sprite.texture = Art.tower()


func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)

	var target: Enemy = _nearest_enemy()
	if target == null:
		return

	# Apuntamos hacia el enemigo más cercano.
	rotation = (target.global_position - global_position).angle()

	if fire_cooldown <= 0.0:
		_shoot(target)
		fire_cooldown = fire_interval


## Busca el enemigo más cercano dentro del rango (o null si no hay).
func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null:
			continue
		var dist: float = global_position.distance_to(e.global_position)
		if dist <= range_radius and dist < best_dist:
			best_dist = dist
			best = e
	return best


## Dispara un proyectil hacia el objetivo.
func _shoot(target: Enemy) -> void:
	var p: Projectile = projectile_scene.instantiate()
	p.target = target
	p.damage = damage
	p.global_position = global_position
	get_parent().add_child(p)


## Recibe daño de los enemigos que la atacan.
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		die()


## Al destruirse, se saca de la grilla para liberar la celda.
func die() -> void:
	grid.remove_tower(cell)
	queue_free()
