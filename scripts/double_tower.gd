class_name DoubleTower
extends Tower

## Torre doble: dispara al doble de velocidad que la torre normal.
## Recarga a la mitad de tiempo (0.4s vs 0.8s) para el doble de presión.


## Textura propia: dos aguijones.
func _texture() -> Texture2D:
	return Art.double_tower()
