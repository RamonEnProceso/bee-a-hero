class_name LongRange
extends Ally

## Largo alcance: dispara un aguijón al enemigo más cercano aunque esté lejos,
## con la mitad de cadencia de una torre común (1.6 s vs 0.8 s).


## Textura propia: abeja celeste y fina.
func _texture() -> Texture2D:
	return Art.long_range()
