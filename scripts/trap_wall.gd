class_name TrapWall
extends Node2D

## Pared trampa (como los pinchos de Bloons): NO bloquea el paso. Cuando un enemigo
## la toca, desaparece y le hace el daño de un proyectil básico.

## Daño que hace al enemigo que la pisa (= daño de un proyectil básico).
@export var damage: int = 2
## Distancia a la que un enemigo activa la trampa.
@export var trigger_radius: float = 20.0

var grid: HexGrid
var cell: Vector2i
var hex_size: float = 32.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = Art.trap()


func _process(_delta: float) -> void:
	var e := _overlapping_enemy()
	if e != null:
		e.take_damage(damage)
		_trigger()


## Primer enemigo vivo que esté encima de la trampa, o null.
func _overlapping_enemy() -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e != null and not e.dead and global_position.distance_to(e.global_position) <= trigger_radius:
			return e
	return null


## La trampa se consume: se saca de la grilla y desaparece.
func _trigger() -> void:
	grid.remove_trap(cell)
	queue_free()
