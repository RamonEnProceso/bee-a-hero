class_name Building
extends Node2D

## Edificio: ocupa 4 hexágonos y habilita 3 slots de abejas-torre.
## Mientras se construye (build_rounds > 0) ocupa sus celdas pero no se puede
## atacar. Al terminarse (o al instante si build_rounds == 0) suma slots y pasa
## a dar su recompensa cada oleada. Al romperse resta los slots.

## Vida del edificio (1,5 veces un muro normal de 5 hp).
@export var max_health: int = 8
## Cuántos slots de abeja suma al terminarse (y restará al destruirse).
@export var slots_granted: int = 3
## Rondas que tarda en construirse (0 = se construye al instante).
@export var build_rounds: int = 0

# Referencia a la grilla dueña (para avisarle cuando se rompe).
var grid: HexGrid
# La celda "ancla" del edificio (la primera de las 4).
var cell: Vector2i
# Las 4 celdas que ocupa.
var cells: Array[Vector2i] = []
# Tamaño de hexágono; lo asigna la grilla al construir.
var hex_size: float = 32.0

var health: int
## true cuando ya está terminado (o si es instantáneo).
var built: bool = true
# Rondas que faltan para terminar la construcción.
var _construction_left: int = 0
var _hit_tween: Tween
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	sprite.texture = _texture()
	add_to_group("buildings")
	Fx.squash(sprite)
	_construction_left = build_rounds
	if build_rounds <= 0:
		_finish_construction()
	else:
		built = false
		sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)


## Marca el edificio como terminado: suma slots y recupera su color.
func _finish_construction() -> void:
	built = true
	sprite.modulate = Color.WHITE
	Fx.squash(sprite)
	Game.increase_capacity(slots_granted)
	# Feedback: sonido y ráfaga de partículas (momento de "desbloqueo").
	Sfx.ding()
	Fx.burst(get_parent(), global_position, Color(1.0, 0.85, 0.4), 16)


## Hook al final de cada oleada: si está en obra, avanza; si ya está listo, da su recompensa.
func on_wave_cleared() -> void:
	if not built:
		_construction_left -= 1
		if _construction_left <= 0:
			_finish_construction()
		return
	_reward()


## Recompensa al terminar cada oleada (las subclases la sobrescriben).
func _reward() -> void:
	pass


## Textura del edificio (cada subtipo devuelve la suya).
func _texture() -> Texture2D:
	return Art.building()


## Resta vida al edificio; en obra no se puede atacar.
func take_damage(amount: int, _attacker: Enemy = null) -> void:
	if not built:
		return
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


## Al destruirse libera sus celdas y resta sus slots, eliminando las últimas
## abejas colocadas (LIFO) hasta entrar en la nueva capacidad.
func die() -> void:
	grid.remove_building(self)
	var removed: Array[Node] = Game.decrease_capacity(slots_granted)
	for node in removed:
		if node is Tower and is_instance_valid(node):
			node.die()
		elif is_instance_valid(node):
			node.queue_free()
	# Feedback: la cámara se sacude al perder un edificio.
	Fx.shake(get_viewport().get_camera_2d())
	queue_free()
