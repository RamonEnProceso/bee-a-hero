class_name LongRange
extends Ally

## Largo alcance: dispara un aguijón al enemigo más cercano aunque esté lejos,
## con la mitad de cadencia de una torre común (1.6 s vs 0.8 s).


## Frame de aleteo propio: abeja celeste y fina.
func _texture_frame(level: int, frame: int) -> Texture2D:
	return Art.long_range_frame(level, frame)
