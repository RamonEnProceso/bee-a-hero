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


## Ráfaga de partículas en `world_pos` (feedback al construir).
static func burst(parent: Node, world_pos: Vector2, color: Color = Color(1.0, 0.85, 0.4), count: int = 10) -> void:
	if parent == null:
		return
	var b := Burst.new()
	b.color = color
	b.count = count
	parent.add_child(b)
	b.global_position = world_pos


## Número flotante que sube y se desvanece (ej. "+5" al juntar miel).
static func float_text(parent: Node, world_pos: Vector2, text: String, color: Color = Color(1.0, 0.9, 0.4)) -> void:
	if parent == null:
		return
	var holder := Node2D.new()
	holder.z_index = 20
	parent.add_child(holder)
	holder.global_position = world_pos
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.05))
	label.add_theme_constant_override("outline_size", 6)
	holder.add_child(label)
	label.position = Vector2(-20.0, -28.0)
	var tw := holder.create_tween()
	tw.tween_property(holder, "position:y", holder.position.y - 40.0, 0.8)
	tw.parallel().tween_property(holder, "modulate:a", 0.0, 0.8)
	tw.tween_callback(holder.queue_free)


## Sacude la cámara (feedback al perder un edificio).
static func shake(camera: Camera2D, amount: float = 6.0) -> void:
	if camera == null:
		return
	var tw := camera.create_tween()
	for i in 6:
		var off := Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		tw.tween_property(camera, "offset", off, 0.02)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.05)
