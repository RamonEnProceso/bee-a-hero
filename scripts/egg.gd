class_name Huevo
extends Node2D

## Huevo de polilla: se queda cerca de la reina y, al cabo de `hatch_time`,
## eclosiona soltando una avispa dentro de la colmena.

## Segundos hasta que eclosiona.
@export var hatch_time: float = 30.0
## Escena de la avispa que suelta al eclosionar.
@export var enemy_scene: PackedScene

## La reina (para que la avispa que nazca la persiga).
var target: Queen
## La grilla (para que la avispa detecte estructuras).
var hex_grid: HexGrid

var _timer: float = 0.0
var _t: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = Art.egg()
	_timer = hatch_time


func _process(delta: float) -> void:
	# Late (escala) para avisar que está por eclosionar.
	_t += delta
	sprite.scale = Vector2.ONE * (1.0 + 0.12 * sin(_t * 5.0))
	_timer -= delta
	if _timer <= 0.0:
		_hatch()


## Suelta la avispa y desaparece.
func _hatch() -> void:
	if enemy_scene != null:
		var wasp: Enemy = enemy_scene.instantiate()
		wasp.target = target
		wasp.hex_grid = hex_grid
		get_parent().add_child(wasp)
		wasp.global_position = global_position
	queue_free()
