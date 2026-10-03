class_name ReinforcedWall
extends Wall

## Pared reforzada: más vida, para frenar a los avispones.


## Textura más sólida.
func _texture() -> Texture2D:
	return Art.reinforced_wall()
