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

## Tipo de construcción (para leer costo de venta y stats de mejora).
@export var build_type: int = 3  # Game.BuildType.TOWER
## Nivel de mejora actual (1 a 3).
var level: int = 1
## Stats base capturados al crearse (para aplicar multiplicadores por nivel).
var _base_fire_interval: float
var _base_damage: int
var _base_max_health: int
## Etiqueta del nivel (solo nivel 2 y 3).
var _level_label: Label


func _ready() -> void:
	_base_fire_interval = fire_interval
	_base_damage = damage
	_base_max_health = max_health
	health = max_health
	_apply_level_stats()
	sprite.texture = _texture()
	Fx.squash(sprite)
	_refresh_level_indicator()


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
	# El número de nivel no gira con la torre: lo contra-rotamos para que quede
	# derecho y en una posición fija sobre ella.
	if _level_label != null:
		_level_label.rotation = -rotation
		_level_label.position = Vector2(-8.0, -hex_size * 1.6).rotated(-rotation)

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


## Nombre para el menú contextual.
func display_name() -> String:
	return Game.BUILD_DEFS[build_type]["name"]


## ¿Esta torre/aliado se puede mejorar?
func is_upgradable() -> bool:
	return Game.is_upgradable(build_type)


## Costo para pasar al siguiente nivel (0 si está al máximo).
func upgrade_cost() -> int:
	return Game.upgrade_cost(build_type, level)


## ¿Se puede mejorar ahora (hay nivel disponible y miel suficiente)?
func can_upgrade() -> bool:
	return level < Game.max_level(build_type) and Game.can_afford(upgrade_cost())


## Miel que devuelve vender esta torre.
func sell_value() -> int:
	return Game.sell_value(build_type, level)


## Mejora al siguiente nivel: descuenta miel, sube de nivel y aplica los
## multiplicadores de stats. Devuelve true si se mejoró.
func upgrade() -> bool:
	if not can_upgrade():
		return false
	Game.spend(upgrade_cost())
	level += 1
	_apply_level_stats()
	_refresh_level_indicator()
	Sfx.upgrade()
	Fx.burst(get_parent(), global_position, Color(0.5, 1.0, 0.7), 14)
	return true


## Aplica los multiplicadores del nivel actual sobre los stats base.
func _apply_level_stats() -> void:
	var fire_mult: float = Game.level_stat(build_type, level, "fire_mult", 1.0)
	var damage_mult: float = Game.level_stat(build_type, level, "damage_mult", 1.0)
	var health_mult: float = Game.level_stat(build_type, level, "health_mult", 1.0)
	fire_interval = _base_fire_interval * fire_mult
	damage = int(round(_base_damage * damage_mult))
	var new_max: int = int(round(_base_max_health * health_mult))
	if new_max > max_health:
		health += new_max - max_health
	max_health = new_max
	health = mini(health, max_health)


## Salta directo a `lvl` (para colocar torres gratis que ya vienen mejoradas).
func set_level(lvl: int) -> void:
	level = clampi(lvl, 1, Game.max_level(build_type))
	_apply_level_stats()
	_refresh_level_indicator()


## Vende la torre: devuelve 3/8 de lo invertido y la retira.
func sell() -> void:
	var refund: int = sell_value()
	Game.gain(refund)
	Sfx.coin()
	Fx.float_text(get_parent(), global_position, "+%d" % refund)
	die()


## Muestra el nivel actual sobre la torre (nivel 1 no muestra nada).
func _refresh_level_indicator() -> void:
	if level <= 1:
		if _level_label != null:
			_level_label.queue_free()
			_level_label = null
		return
	if _level_label == null:
		_level_label = Label.new()
		_level_label.z_index = 30
		_level_label.add_theme_font_size_override("font_size", 12)
		_level_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
		_level_label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.05))
		_level_label.add_theme_constant_override("outline_size", 4)
		add_child(_level_label)
	_level_label.text = str(level)
	_level_label.position = Vector2(-8.0, -hex_size * 1.6)
