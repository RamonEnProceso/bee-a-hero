class_name BuilderBee
extends Node2D

## La abeja protagonista (constructora): se mueve por el panal y la cámara la sigue.
## Es invulnerable: no tiene vida ni recibe daño.

@export var speed: float = 160.0
@export var body_color: Color = Color(1.0, 0.85, 0.2)
@export var stripe_color: Color = Color(0.25, 0.18, 0.05)
@export var outline_color: Color = Color(0.35, 0.26, 0.06)

## Referencia a la grilla (para mantener a la abeja dentro del panal).
var grid: HexGrid


func _ready() -> void:
	# La cámara es hija nuestra: se mueve con la abeja automáticamente.
	$Camera2D.make_current()


func _process(delta: float) -> void:
	# Movimiento WASD + flechas. Es un Node2D simple (no choca con nada).
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0

	position += dir.normalized() * speed * delta

	# La mantenemos cerca del panal para que no se pierda por la pantalla.
	if grid != null:
		var max_dist: float = (grid.grid_radius + 2.0) * grid.hex_size * 1.5
		if position.length() > max_dist:
			position = position.normalized() * max_dist


func _draw() -> void:
	# Placeholder: abeja = círculo amarillo con rayas oscuras.
	var r := 10.0
	draw_circle(Vector2.ZERO, r, body_color)
	draw_line(Vector2(-r * 0.5, -r * 0.7), Vector2(-r * 0.5, r * 0.7), stripe_color, 3.0, true)
	draw_line(Vector2(0.0, -r * 0.8), Vector2(0.0, r * 0.8), stripe_color, 3.0, true)
	draw_line(Vector2(r * 0.5, -r * 0.7), Vector2(r * 0.5, r * 0.7), stripe_color, 3.0, true)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, outline_color, 1.5, true)
