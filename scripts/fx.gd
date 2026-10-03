class_name Fx
extends RefCounted

## Efectos de "game feel" reutilizables.


## Squash al colocar: el objeto se agranda, se achica y vuelve a su tamaño.
## Da la ilusión de haber sido soltado desde arriba.
static func squash(node: Node2D) -> void:
	if node == null:
		return
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.25, 0.75), 0.08)
	tw.tween_property(node, "scale", Vector2(0.85, 1.15), 0.1)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12)
