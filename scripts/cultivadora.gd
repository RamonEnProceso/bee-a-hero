class_name Cultivadora
extends Building

## Cultivadora: tarda 1 ronda en construirse y genera 100 de miel al terminar
## cada oleada.


## Textura propia (puerta violeta).
func _texture() -> Texture2D:
	return Art.cultivadora()


## Genera miel al final de cada oleada según su nivel (x1, x2, x3,5).
func _reward() -> void:
	Game.gain(Game.level_stat(build_type, level, "honey", 100))
