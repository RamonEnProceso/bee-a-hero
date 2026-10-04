class_name DoubleTower
extends Tower

## Torre doble: dispara al doble de velocidad que la torre normal.
## Recarga a la mitad de tiempo (0.4s vs 0.8s) para el doble de presión.
## Al mejorar sube la cadencia: nivel 2 = x2 y nivel 3 = x6 disparos por segundo.


## Frame de aleteo propio: abeja con dos aguijones.
func _texture_frame(level: int, frame: int) -> Texture2D:
	return Art.double_tower_frame(level, frame)
