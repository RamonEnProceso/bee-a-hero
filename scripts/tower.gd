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
## Celdas que ocupa esta torre (una sola).
var cells: Array[Vector2i] = []
var hex_size: float = 32.0

var health: int
var fire_cooldown: float = 0.0
var _hit_tween: Tween
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	sprite.texture = _texture()
	Fx.squash(sprite)


## Textura de la torre (la doble devuelve la suya).
func _texture() -> Texture2D:
	return Art.tower()


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
	var list := _enemies_in_range()
	if list.is_empty():
		return null
	return list[0]


## Enemigos vivos dentro del rango, del más cercano al más lejano.
func _enemies_in_range() -> Array[Enemy]:
	var list: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null or e.dead:
			continue
		if global_position.distance_to(e.global_position) <= range_radius:
			list.append(e)
	list.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	return list


## Dispara un proyectil hacia el objetivo.
func _shoot(target: Enemy) -> void:
	_spawn_projectile(target)


## Crea el proyectil que viaja hacia `target`. Las subclases lo sobrescriben
## (la torre doble recarga más rápido).
func _spawn_projectile(target: Enemy) -> void:
	var p: Projectile = projectile_scene.instantiate()
	p.target = target
	p.damage = damage
	p.global_position = global_position
	get_parent().add_child(p)


## Recibe daño de los enemigos que la atacan.
func take_damage(amount: int, _attacker: Enemy = null) -> void:
	health = maxi(0, health - amount)
	_hit_flash()
	if health <= 0:
		die()


## Al recibir daño se achica y se pone roja, y vuelve a la normalidad.
func _hit_flash() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	sprite.modulate = Color(1.0, 0.3, 0.3)
	sprite.scale = Vector2(0.7, 0.7)
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15)


## Al destruirse, se saca de la grilla para liberar la celda y el slot.
func die() -> void:
	grid.remove_tower(self)
	Game.unregister_slotted(self)
	queue_free()
