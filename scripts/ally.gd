class_name Ally
extends Tower

## Base de los aliados: abejas defensoras que ocupan un slot y pelean por la reina.
## Reutiliza todo lo de Tower (apuntar al enemigo más cercano, recibir daño, slot).
## Cada subtipo cambia textura y su forma de atacar: el guardia y las pirañas pegan
## cuerpo a cuerpo; la de largo alcance dispara un aguijón.

## Posición de casa (la celda donde se colocó). Las pirañas "vuelven" acá.
var home_position: Vector2

var _lunge_tween: Tween


func _ready() -> void:
	super()
	home_position = global_position


## Embiste visual hacia `dir`: el sprite sale una distancia y vuelve a su lugar.
## Los aliados cuerpo a cuerpo lo usan para dar la sensación de mordida/embestida.
func _lunge(dir: Vector2, distance: float = 10.0) -> void:
	if _lunge_tween != null and _lunge_tween.is_valid():
		_lunge_tween.kill()
	sprite.position = Vector2.ZERO
	_lunge_tween = create_tween()
	_lunge_tween.tween_property(sprite, "position", dir * distance, 0.06)
	_lunge_tween.tween_property(sprite, "position", Vector2.ZERO, 0.14)
