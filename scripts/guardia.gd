class_name Guardia
extends Ally

## Guardia: abeja gorda cuerpo a cuerpo. Vida 6 (algo más que un muro de 5),
## pega el doble de daño que una torre básica, pero solo de cerca (60 px).


## Textura propia: abeja gorda naranja.
func _texture() -> Texture2D:
	return Art.guardia()


## Cuerpo a cuerpo: daño directo al objetivo + una embestida corta.
func _shoot(target: Enemy) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	target.take_damage(damage, dir)
	_lunge(dir, 8.0)
