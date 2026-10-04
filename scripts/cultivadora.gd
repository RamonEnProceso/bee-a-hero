class_name Cultivadora
extends Building

## Cultivadora: tarda 1 ronda en construirse y genera 100 de miel al terminar
## cada oleada. Una vez terminada, se inclina apenas a los lados (skew) para
## parecer que está laburando.

## Ángulo de inclinación del latido (radianes, ~1.4°). Al estar el pivote en la
## base, solo se mueve la parte de arriba.
const WORK_SKEW := 0.025

## Tween del latido de "trabajo" (inclinación en bucle).
var _work_tween: Tween


## Textura propia.
func _texture() -> Texture2D:
	return Art.cultivadora()


## Genera miel al final de cada oleada según su nivel (x1, x2, x3,5).
func _reward() -> void:
	Game.gain(Game.level_stat(build_type, level, "honey", 100))


## Tras el _ready base, mueve el pivote del sprite al centro de su base.
func _ready() -> void:
	super._ready()
	_anchor_pivot_at_base()


## Mueve el pivote del sprite al centro de su base y compensa la posición para que
## siga centrado en la celda. Así el skew inclina solo la parte de arriba.
func _anchor_pivot_at_base() -> void:
	if sprite.texture == null:
		return
	var w: float = sprite.texture.get_width()
	var h: float = sprite.texture.get_height()
	sprite.centered = false
	# Con centered=false el pivote queda en la coordenada de textura -offset.
	# (-w/2, -h) lo ancla al centro de la base del sprite.
	sprite.offset = Vector2(-w / 2.0, -h)
	sprite.position.y += (h * _base_scale.y) / 2.0
	_base_position = sprite.position


## Al terminar la obra, además de lo habitual, arranca el latido de trabajo.
func _finish_construction() -> void:
	super._finish_construction()
	_start_work_pulse()


## Latido en bucle: el sprite se inclina a la derecha y a la izquierda (skew),
## anclado en la base, para que solo se mueva la parte de arriba.
func _start_work_pulse() -> void:
	_work_tween = create_tween().set_loops()
	_work_tween.tween_property(sprite, "skew", WORK_SKEW, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_work_tween.tween_property(sprite, "skew", -WORK_SKEW, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_work_tween.tween_property(sprite, "skew", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
