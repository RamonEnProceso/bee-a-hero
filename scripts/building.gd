class_name Building
extends Node2D

## Edificio base: ocupa 3 hexágonos y, al construirse, habilita slots de
## abejas-torre. Los enemigos lo atacan; al romperlo se pierden esos slots.

## Vida del edificio (1,5 veces un muro normal de 5 hp).
@export var max_health: int = 8
## Cuántos slots de abeja suma al construirse (y restará al destruirse).
@export var slots_granted: int = 3

# Referencia a la grilla dueña (para avisarle cuando se rompe).
var grid: HexGrid
# La celda "ancla" del edificio (la primera de las 3).
var cell: Vector2i
# Las 3 celdas que ocupa.
var cells: Array[Vector2i] = []
# Tamaño de hexágono; lo asigna la grilla al construir.
var hex_size: float = 32.0

var health: int
var _hit_tween: Tween
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	sprite.texture = _texture()
	Fx.squash(sprite)
	# Al construirse amplía la cantidad de abejas que podemos colocar.
	Game.increase_capacity(slots_granted)


## Textura del edificio (cada subtipo devuelve la suya).
func _texture() -> Texture2D:
	return Art.building()


## Resta vida al edificio; al llegar a 0 se destruye.
func take_damage(amount: int, _attacker: Enemy = null) -> void:
	health = maxi(0, health - amount)
	_shake()
	if health <= 0:
		die()


## Vibra al recibir un golpe (igual que las paredes).
func _shake() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	sprite.position = Vector2.ZERO
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "position", Vector2(3.0, 0.0), 0.035)
	_hit_tween.tween_property(sprite, "position", Vector2(-3.0, 0.0), 0.035)
	_hit_tween.tween_property(sprite, "position", Vector2.ZERO, 0.035)


## Al destruirse, libera sus celdas (los slots se restan en la Etapa 3).
func die() -> void:
	grid.remove_building(self)
	queue_free()
