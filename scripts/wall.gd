class_name Wall
extends Node2D

@export var max_health: int = 5
@export var body_color: Color = Color(0.55, 0.35, 0.15)
@export var outline_color: Color = Color(0.30, 0.18, 0.08)

# Referencia a la grilla dueña (para avisarle cuando la pared se rompe).
var grid: HexGrid
# La celda que ocupa esta pared.
var cell: Vector2i
# Tamaño de hexágono; lo asigna la grilla al construir, para dibujar acorde.
var hex_size: float = 32.0

var health: int


func _ready() -> void:
	health = max_health


## Resta vida a la pared; si llega a 0, se rompe y se libera de la grilla.
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	queue_redraw()
	if health <= 0:
		_break()


func _break() -> void:
	grid.remove_wall(cell)
	queue_free()


func _draw() -> void:
	# Pared = hexágono marrón que rellena la celda. Se aclara a medida que pierde vida.
	var t: float = float(health) / float(max_health)
	var points := PackedVector2Array()
	for i in 6:
		var angle: float = deg_to_rad(60.0 * i - 30.0)
		points.append(Vector2(cos(angle), sin(angle)) * hex_size * 0.85)
	draw_colored_polygon(points, body_color.lerp(Color.WHITE, 0.4 * (1.0 - t)))

	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, outline_color, 2.0, true)
