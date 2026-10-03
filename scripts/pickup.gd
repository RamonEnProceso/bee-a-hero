class_name Pickup
extends Node2D

## Gota de miel que suelta un enemigo al morir. La abeja protagonista la recolecta:
## si se acerca, la gota sale volando hacia ella (como los orbes de God of War).

## Cuánta miel da al recolectarla.
@export var value: int = 5
## Distancia a la que empieza a ser atraída hacia la abeja.
@export var magnet_radius: float = 90.0
## Distancia a la que se considera recolectada.
@export var collect_radius: float = 14.0
## Velocidad con la que vuela hacia la abeja.
@export var magnet_speed: float = 320.0
## Tiempo máximo de vida, para que no queden gotas viejas por ahí.
@export var lifetime: float = 20.0

## Textura real de la partícula de miel que suelta el enemigo (PNG de 64px).
const HONEY_TEXTURE: Texture2D = preload("res://textures/Miel_particula.png")
## Escala del sprite (el PNG viene a 64px, hay que achicarlo).
@export var sprite_scale: float = 0.25

var _bee: Node2D  # la abeja protagonista (grupo "player")
var _t: float = 0.0  # para el bobbing
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = HONEY_TEXTURE
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	add_to_group("pickups")
	_bee = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	# Si no encontramos a la abeja (o aparece después), la buscamos de nuevo.
	if _bee == null:
		_bee = get_tree().get_first_node_in_group("player")
		if _bee == null:
			return

	var dist: float = global_position.distance_to(_bee.global_position)

	# Se recoge al tocarla.
	if dist <= collect_radius:
		Game.gain(value)
		Fx.float_text(get_parent(), global_position, "+%d" % value)
		queue_free()
		return

	# Si la abeja está cerca, la gota sale volando hacia ella.
	if dist <= magnet_radius:
		global_position = global_position.move_toward(_bee.global_position, magnet_speed * delta)
	else:
		# Quieta: flota un poquito para que se vea viva.
		_t += delta
		sprite.position.y = sin(_t * 3.0) * 2.0

	# Desaparece si no la recogen a tiempo.
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
