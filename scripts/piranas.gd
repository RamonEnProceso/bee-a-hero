class_name Piranas
extends Ally

## Pirañas: enjambre de abejas chicas. Ocupan 4 slots, tienen poca vida y atacan
## a corta distancia, pero rápido. Embisten hacia el enemigo y vuelven a su lugar.


## Textura propia: enjambre rojo chico.
func _texture() -> Texture2D:
	return Art.piranas()


## Mordida a corta distancia: daño directo y una embestida grande (salen y vuelven).
func _shoot(target: Enemy) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	target.take_damage(damage, dir)
	_lunge(dir, 16.0)
