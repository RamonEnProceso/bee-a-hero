class_name Wall
extends Node2D

## Pared: bloquea el paso de los enemigos y tiene vida propia.
## Los subtipos (reforzada, de púas) heredan y cambian textura/vida.

@export var max_health: int = 5
## Daño que devuelve al enemigo que la golpea (0 = sin púas).
@export var thorns: int = 0

# Referencia a la grilla dueña (para avisarle cuando la pared se rompe).
var grid: HexGrid
# La celda que ocupa esta pared.
var cell: Vector2i
# Tamaño de hexágono; lo asigna la grilla al construir.
var hex_size: float = 32.0

var health: int
var _hit_tween: Tween
@onready var sprite: Sprite2D = $Sprite2D

## Tipo de construcción (para leer el costo de venta).
@export var build_type: int = 0  # Game.BuildType.WALL
## Las paredes no se mejoran: nivel fijo en 1.
var level: int = 1


func _ready() -> void:
	health = max_health
	sprite.texture = _texture()
	Fx.squash(sprite)


## Textura de la pared (cada subtipo devuelve la suya).
func _texture() -> Texture2D:
	return Art.wall()


## Resta vida a la pared; si es de púas, le devuelve daño al atacante.
func take_damage(amount: int, attacker: Enemy = null) -> void:
	health = maxi(0, health - amount)
	if attacker != null and thorns > 0:
		attacker.take_damage(thorns)
	_shake()
	if health <= 0:
		_break()


## Vibra al recibir un golpe (las paredes solo vibran, no cambian de color).
func _shake() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	sprite.position = Vector2.ZERO
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "position", Vector2(3.0, 0.0), 0.035)
	_hit_tween.tween_property(sprite, "position", Vector2(-3.0, 0.0), 0.035)
	_hit_tween.tween_property(sprite, "position", Vector2.ZERO, 0.035)


## Se rompe (por un enemigo): libera la celda y desaparece.
func _break() -> void:
	grid.remove_wall(cell)
	queue_free()


## Nombre para el menú contextual.
func display_name() -> String:
	return Game.BUILD_DEFS[build_type]["name"]


## Las paredes no se mejoran.
func is_upgradable() -> bool:
	return false


## Sin costo de mejora (no se puede mejorar).
func upgrade_cost() -> int:
	return 0


## Nunca se puede mejorar.
func can_upgrade() -> bool:
	return false


## Miel que devuelve vender esta pared.
func sell_value() -> int:
	return Game.sell_value(build_type, level)


## Vende la pared: devuelve 3/8 de su costo y la retira.
func sell() -> void:
	var refund: int = sell_value()
	Game.gain(refund)
	Sfx.coin()
	Fx.float_text(get_parent(), global_position, "+%d" % refund)
	_break()
