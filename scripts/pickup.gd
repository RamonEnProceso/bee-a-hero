class_name Pickup
extends Node2D

## Gota de miel que suelta un enemigo al morir; la abeja protagonista la recolecta al acercarse.

## Cuánta miel da al recolectarla.
@export var value: int = 5
## Distancia a la que la abeja la recoge.
@export var pickup_radius: float = 24.0
## Tiempo máximo de vida, para que no queden gotas viejas por ahí.
@export var lifetime: float = 20.0

var _bee: Node2D  # la abeja protagonista (grupo "player")
var _t: float = 0.0  # para el bobbing
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = Art.pickup()
	_bee = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	# Si no encontramos a la abeja (o aparece después), la buscamos de nuevo.
	if _bee == null:
		_bee = get_tree().get_first_node_in_group("player")
		if _bee == null:
			return

	# Se recoge cuando la abeja está lo bastante cerca.
	if global_position.distance_to(_bee.global_position) <= pickup_radius:
		Game.gain(value)
		queue_free()
		return

	# Desaparece si no la recogen a tiempo.
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Flota un poquito para que se vea viva.
	_t += delta
	sprite.position.y = sin(_t * 3.0) * 2.0
