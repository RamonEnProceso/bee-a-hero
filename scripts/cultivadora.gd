class_name Cultivadora
extends Building

## Cultivadora: tarda 1 ronda en construirse y genera 100 de miel al terminar
## cada oleada.


## Textura propia (puerta violeta).
func _texture() -> Texture2D:
	return Art.cultivadora()


## Genera miel al final de cada oleada.
func _reward() -> void:
	Game.gain(100)
