class_name ShooterWasp
extends Enemy

## Avispa tiradora: avanza como una avispa normal pero además dispara aguijones
## a la reina cada tanto. Los aguijones se pueden frenar con paredes.

## Escena del aguijón que dispara.
@export var projectile_scene: PackedScene
## Segundos entre disparos.
@export var shoot_interval: float = 2.2
## Daño de cada aguijón.
@export var shot_damage: int = 1
## Distancia máxima a la reina para empezar a disparar (px).
@export var shoot_range: float = 340.0

var _shoot_timer: float = 0.0


## Los dos frames del aleteo de la avispa tiradora.
const TIRADORA_TEXTURES := [
	preload("res://textures/AvispaTiradora_00.png"),
	preload("res://textures/AvispaTiradora_01.png"),
]


func _textures() -> Array:
	return TIRADORA_TEXTURES


func _ready() -> void:
	super()
	# El primer tiro sale un poco antes para no quedar tan pasivo.
	_shoot_timer = shoot_interval * 0.6


func _process(delta: float) -> void:
	if dead or target == null:
		return
	# Dispara cada `shoot_interval` segundos si está a tiro de la reina.
	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and global_position.distance_to(target.global_position) <= shoot_range:
		_shoot()
		_shoot_timer = shoot_interval
	# Movimiento normal (línea recta, ataca estructuras, llega a la reina).
	super(delta)


## Dispara un aguijón hacia la reina.
func _shoot() -> void:
	if projectile_scene == null:
		return
	var p: EnemyProjectile = projectile_scene.instantiate()
	p.damage = shot_damage
	p.target = target
	p.hex_grid = hex_grid
	p.global_position = global_position
	get_parent().add_child(p)
