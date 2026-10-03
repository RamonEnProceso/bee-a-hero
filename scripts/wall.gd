class_name Wall
extends Node2D

## Pared: bloquea el paso de los enemigos y tiene vida propia.

@export var max_health: int = 5

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
	sprite.texture = Art.wall()


## Resta vida a la pared; si llega a 0, se rompe y se libera de la grilla.
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		_break()


func _break() -> void:
	grid.remove_wall(cell)
	queue_free()
