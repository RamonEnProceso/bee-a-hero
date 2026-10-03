class_name Queen
extends Node2D

## La reina: si se queda sin vida, perdemos.
## Se anima con los dos sprites de aleteo y un vaivén vertical de vuelo.

## Se emite cuando la reina llega a 0 de vida (derrota).
signal died
## Se emite cada vez que cambia la vida (para la UI).
signal health_changed(current: int, maximum: int)

@export var max_health: int = 10

## Escala del sprite (los PNG vienen a 512px, hay que achicarlos).
@export var sprite_scale: float = 0.16
## Segundos por frame del aleteo (más chico = alas más rápidas).
@export var flap_interval: float = 0.1
## Amplitud del vaivén vertical (px) para el efecto de vuelo.
@export var bob_amplitude: float = 4.0
## Velocidad del vaivén vertical (radianes/segundo).
@export var bob_speed: float = 8.0

## Los dos frames del aleteo.
const FLAP_TEXTURES := [
	preload("res://textures/AbejaReina00.png"),
	preload("res://textures/AbejaReina01.png"),
]

var health: int
var _hit_tween: Tween
var _flap_timer: float = 0.0
var _flap_frame: int = 0
var _bob_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.texture = FLAP_TEXTURES[0]


func _process(delta: float) -> void:
	# Aleteo: alterna los dos frames en bucle.
	_flap_timer += delta
	if _flap_timer >= flap_interval:
		_flap_timer = 0.0
		_flap_frame = 1 - _flap_frame
		sprite.texture = FLAP_TEXTURES[_flap_frame]
	# Vaivén vertical: siempre sube y baja para simular el vuelo.
	_bob_time += delta
	sprite.position.y = sin(_bob_time * bob_speed) * bob_amplitude


## Resta vida a la reina y avisa por señal si murió o si cambió la vida.
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	_hit_flash()
	if health <= 0:
		died.emit()


## Al recibir daño se achica, se pone roja y vuelve a su tamaño normal.
func _hit_flash() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	var base := Vector2(sprite_scale, sprite_scale)
	sprite.modulate = Color(1.0, 0.3, 0.3)
	sprite.scale = base * 0.7
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "scale", base, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15)
