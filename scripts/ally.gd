class_name Ally
extends Tower

## Base de los aliados: abejas defensoras que ocupan un slot y pelean por la reina.
## Reutiliza todo lo de Tower (apuntar al enemigo más cercano, recibir daño, slot).
## Cada subtipo cambia textura y su forma de atacar: el guardia pega
## cuerpo a cuerpo; la de largo alcance dispara un aguijón.

## Posición de casa (la celda donde se colocó). El guardia "vuelve" acá.
var home_position: Vector2

var _lunge_tween: Tween


func _ready() -> void:
	super()
	home_position = global_position


## Embiste visual hacia `dir`: suma un offset temporal que sale y vuelve. Se suma al
## vaivén de vuelo (Tower._animate_flight) para no pisar el bob.
func _lunge(dir: Vector2, distance: float = 10.0) -> void:
	if _lunge_tween != null and _lunge_tween.is_valid():
		_lunge_tween.kill()
	var peak := dir * distance
	_lunge_tween = create_tween()
	_lunge_tween.tween_method(func(v: Vector2) -> void: _lunge_offset = v, Vector2.ZERO, peak, 0.06)
	_lunge_tween.tween_method(func(v: Vector2) -> void: _lunge_offset = v, peak, Vector2.ZERO, 0.14)
