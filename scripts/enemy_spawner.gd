class_name EnemySpawner
extends Node2D

## Genera oleadas de avispas: cada oleada trae más enemigos y hay una pausa entre oleadas.

## Escena del enemigo a instanciar.
@export var enemy_scene: PackedScene
## Enemigos de la primera oleada.
@export var base_enemies: int = 5
## Cuántos enemigos se suman en cada oleada nueva.
@export var enemies_per_wave: int = 2
## Segundos entre un spawn y el siguiente dentro de la oleada.
@export var spawn_interval: float = 1.5
## Pausa entre el final de una oleada y el inicio de la siguiente.
@export var time_between_waves: float = 8.0

## Se emite al arrancar una oleada (con su número).
signal wave_started(wave: int)
## Se emite cuando mueren todos los enemigos de la oleada.
signal wave_cleared(wave: int)

# Referencias que Main completa en _ready.
var hex_grid: HexGrid
var queen: Queen

# Número de oleada actual.
var wave: int = 0
# Enemigos que quedan por soltar en la oleada en curso.
var _to_spawn: int = 0
# Enemigos de esta oleada que siguen vivos.
var _alive: int = 0
# Temporizadores internos.
var _spawn_timer: float = 0.0
var _wait_timer: float = 0.0


func _ready() -> void:
	# La primera oleada arranca un poco después de entrar al juego.
	_wait_timer = 3.0


func _process(delta: float) -> void:
	# Si Main todavía no inyectó las referencias, no hacemos nada.
	if queen == null or hex_grid == null:
		return

	# Entre oleadas: esperamos y arrancamos la siguiente.
	if _to_spawn <= 0 and _alive <= 0:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_start_next_wave()
		return

	# Dentro de una oleada: soltamos enemigos de a uno.
	if _to_spawn > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_one()
			_spawn_timer = spawn_interval


func _start_next_wave() -> void:
	wave += 1
	_to_spawn = base_enemies + (wave - 1) * enemies_per_wave
	_alive = 0
	wave_started.emit(wave)


## Crea una avispa en un hexágono del borde y le dice a quién perseguir.
func _spawn_one() -> void:
	var ring: Array[Vector2i] = hex_grid.get_ring_cells()
	if ring.is_empty():
		return
	var cell: Vector2i = ring[randi() % ring.size()]

	var enemy: Enemy = enemy_scene.instantiate()
	enemy.target = queen
	enemy.hex_grid = hex_grid
	enemy.global_position = hex_grid.world_position_of(cell.x, cell.y)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

	_to_spawn -= 1
	_alive += 1


## Cuando muere una avispa de la oleada, contamos la baja.
func _on_enemy_died() -> void:
	_alive -= 1
	if _to_spawn <= 0 and _alive <= 0:
		_wait_timer = time_between_waves
		wave_cleared.emit(wave)
