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
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	sprite.texture = _texture()


## Textura de la pared (cada subtipo devuelve la suya).
func _texture() -> Texture2D:
	return Art.wall()


## Resta vida a la pared; si es de púas, le devuelve daño al atacante.
func take_damage(amount: int, attacker: Enemy = null) -> void:
	health = maxi(0, health - amount)
	if attacker != null and thorns > 0:
		attacker.take_damage(thorns)
	if health <= 0:
		_break()


func _break() -> void:
	grid.remove_wall(cell)
	queue_free()
