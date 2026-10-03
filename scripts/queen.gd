class_name Queen
extends Node2D

## Se emite cuando la reina llega a 0 de vida (derrota).
signal died
## Se emite cada vez que cambia la vida (para la UI de la Etapa 5).
signal health_changed(current: int, maximum: int)

@export var max_health: int = 10
@export var radius: float = 24.0
@export var body_color: Color = Color(1.0, 0.84, 0.25)
@export var outline_color: Color = Color(0.6, 0.45, 0.05)

var health: int


func _ready() -> void:
	# La reina arranca con vida completa.
	health = max_health


## Resta vida a la reina y avisa por señal si murió o si cambió la vida.
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()


func _draw() -> void:
	# Placeholder visual: un círculo dorado (la reina) con contorno.
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, outline_color, 2.0, true)
