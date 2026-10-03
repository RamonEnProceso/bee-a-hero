class_name SpikyWall
extends Wall

## Pared de púas: devuelve daño al enemigo que la golpea.


## Textura con púas.
func _texture() -> Texture2D:
	return Art.spiky_wall()
