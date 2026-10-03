class_name Queen
extends Node2D

## La reina: si se queda sin vida, perdemos.

## Se emite cuando la reina llega a 0 de vida (derrota).
signal died
## Se emite cada vez que cambia la vida (para la UI).
signal health_changed(current: int, maximum: int)

@export var max_health: int = 10

var health: int
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	sprite.texture = Art.queen()


## Resta vida a la reina y avisa por señal si murió o si cambió la vida.
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()
