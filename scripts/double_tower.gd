class_name DoubleTower
extends Tower

## Torre doble: dispara a los dos enemigos más cercanos a la vez.
## Igual de frágil que la torre normal, pero el doble de presión.


## En vez de un proyectil, dispara uno a cada uno de los dos enemigos más cercanos.
func _shoot(_target: Enemy) -> void:
	var list := _enemies_in_range()
	for i in mini(2, list.size()):
		_spawn_projectile(list[i])
