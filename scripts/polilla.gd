class_name Polilla
extends Enemy

## Polilla: vuela en línea recta hacia la reina y, al llegar, pone un huevo que
## eclosiona a los 30 segundos soltando una avispa. Ella misma no daña a la reina.

## Escena del huevo que deja al llegar a la colmena.
@export var egg_scene: PackedScene
## Qué tan cerca de la reina pone el huevo (px).
@export var lay_distance: float = 40.0

var _laid: bool = false


func _texture() -> Texture2D:
	return Art.polilla()


func _process(delta: float) -> void:
	if dead or target == null:
		return
	_apply_knockback(delta)

	# Vuela directo hacia la reina (por encima de las estructuras).
	var dir: Vector2 = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta
	rotation = dir.angle()

	# Al llegar, pone el huevo y se va.
	if global_position.distance_to(target.global_position) <= lay_distance:
		_lay_egg()


## Pone un huevo cerca de la reina y abandona la escena sin dañarla.
func _lay_egg() -> void:
	if _laid:
		return
	_laid = true
	if egg_scene != null:
		var egg: Huevo = egg_scene.instantiate()
		egg.target = target
		egg.hex_grid = hex_grid
		get_parent().add_child(egg)
		egg.global_position = global_position
	leave()
