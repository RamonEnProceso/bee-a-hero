class_name BombWasp
extends Enemy

## Avispa bomba: va hacia la reina como una avispa normal, pero al morir explota
## y daña a las abejas aliadas (torres y aliados) en radio ~1 hexágono.

## Radio del área de la explosión (≈ 1 hexágono).
@export var blast_radius: float = 56.0
## Daño de la explosión a las abejas aliadas cercanas.
@export var explosion_damage: int = 2


func _texture() -> Texture2D:
	return Art.bomb_wasp()


## Al morir, además del comportamiento normal (botín), explota.
func die(reward: bool = false) -> void:
	if dead:
		return
	super.die(reward)
	_explode()


## Explosión: daño en área a torres/aliados cercanos + explosión grande de aviso.
func _explode() -> void:
	# Explosión visual grande (naranja) para que se note.
	var e: Explosion = EXPLOSION_SCENE.instantiate()
	e.max_radius = 60.0
	e.lifetime = 0.35
	e.color = Color(1.0, 0.4, 0.1)
	get_parent().add_child(e)
	e.global_position = global_position

	# Daña cada torre/aliado dentro del radio.
	var seen: Dictionary = {}
	for cell in hex_grid.towers.keys():
		var t: Tower = hex_grid.towers[cell]
		if seen.has(t):
			continue
		seen[t] = true
		if global_position.distance_to(t.global_position) <= blast_radius:
			t.take_damage(explosion_damage)
