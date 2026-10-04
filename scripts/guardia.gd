class_name Guardia
extends Ally

## Patovica: abeja gorda cuerpo a cuerpo. Vida 6 (algo más que un muro de 5),
## pega el doble de daño que una torre básica, pero solo de cerca (60 px).
## Aletea y flota igual que las demás abejas (lo hereda de Tower) y embiste al pegar.


## Frame de aleteo propio: abeja gorda (Patovica).
func _texture_frame(level: int, frame: int) -> Texture2D:
	return Art.guardia_frame(level, frame)


## La Patovica no rota ni se espeja: se queda en su sprite fijo y golpea así,
## solo con la embestida (que sí sale hacia el enemigo, pero sin girar el dibujo).
func _aim(_target: Enemy) -> void:
	pass


## Cuerpo a cuerpo: daño directo al objetivo + una embestida corta.
func _shoot(target: Enemy) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	target.take_damage(damage, dir)
	_lunge(dir, 8.0)
