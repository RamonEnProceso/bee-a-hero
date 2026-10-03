class_name BigTower
extends Tower

## Cañón: ocupa un "2x2" de hexágonos y dispara tiros grandes y potentes.
## Caro, pero mucho daño y mucho alcance. Los stats vienen del .tscn.


## Textura propia: cuerpo oscuro + cañón.
func _texture() -> Texture2D:
	return Art.big_tower()


## Proyectil más grande (escala 1.8x) y con más área de impacto.
func _spawn_projectile(target: Enemy) -> void:
	var p: Projectile = projectile_scene.instantiate()
	p.target = target
	p.damage = damage
	p.hit_radius = 16.0
	p.global_position = global_position
	get_parent().add_child(p)
	p.scale = Vector2(1.8, 1.8)
