class_name EnemySpawner
extends Node2D

## Genera oleadas de enemigos variados: cada oleada agrega tipos nuevos.
## La receta de cada oleada arma una lista de escenas que se sueltan de a uno.

## Escena de la avispa normal.
@export var enemy_scene: PackedScene
## Avispa más grande (desde la oleada 1, resistente al empuje).
@export var big_wasp_scene: PackedScene
## Avispa torbellino: gira en espiral desde el borde hasta el centro (desde la 3).
@export var spiral_wasp_scene: PackedScene
## Avispa tiradora: avanza y dispara aguijones a la reina (desde la 4).
@export var shooter_wasp_scene: PackedScene
## Avispón que rompe paredes (desde la oleada 2).
@export var hornet_scene: PackedScene
## Hormiga: roba la miel sin recolectar y huye (desde la oleada 4).
@export var hormiga_scene: PackedScene

## Enemigos de la primera oleada (pocos, para dar tiempo a construir).
@export var base_enemies: int = 3
## Cuántos enemigos se suman en cada oleada nueva (crecimiento suave).
@export var enemies_per_wave: int = 2
## Segundos entre un spawn y el siguiente dentro de la oleada.
@export var spawn_interval: float = 1.5
## Pausa entre el final de una oleada y el inicio de la siguiente.
## Es la fase de recolección (30 s según el diseño): tiempo para juntar miel y construir.
@export var time_between_waves: float = 30.0
## Espera antes de la primera oleada (tiempo para construir el primer edificio).
@export var first_wave_delay: float = 12.0
## Factor de velocidad de las primeras oleadas (1.0 = velocidad normal).
@export var early_speed_scale: float = 0.6

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
# Cola de escenas de la oleada (ya mezclada).
var _queue: Array[PackedScene] = []
# Temporizadores internos.
var _spawn_timer: float = 0.0
var _wait_timer: float = 0.0


func _ready() -> void:
	# La primera oleada arranca tras un buen rato, para que haya tiempo de construir.
	_wait_timer = first_wave_delay


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
	_queue = _wave_recipe(wave)
	_to_spawn = _queue.size()
	_alive = 0
	wave_started.emit(wave)
	# Desde la oleada 2 hay cerco (media ronda hasta la 4, círculo completo desde la 5).
	if wave >= 2:
		_spawn_encirclement(wave)


## Arma la lista de escenas de la oleada `w` (mezclada) según qué tipos ya aparecieron.
## El arranque es suave: pocas avispas y las amenazas nuevas se suman de a poco.
func _wave_recipe(w: int) -> Array[PackedScene]:
	var list: Array[PackedScene] = []
	# Siempre hay avispas normales de base (pocas al principio, crecen despacio).
	var normals: int = base_enemies + (w - 1) * enemies_per_wave
	for i in normals:
		list.append(enemy_scene)
	# Avispas grandes desde la oleada 2 (la 1 es solo de avispas normales).
	if w >= 2 and big_wasp_scene != null:
		list.append(big_wasp_scene)
	# Avispa torbellino desde la oleada 3.
	if w >= 3 and spiral_wasp_scene != null:
		list.append(spiral_wasp_scene)
	# Avispa tiradora desde la oleada 4.
	if w >= 4 and shooter_wasp_scene != null:
		list.append(shooter_wasp_scene)
	# Avispón (rompe paredes) desde la oleada 2.
	if w >= 2 and hornet_scene != null:
		list.append(hornet_scene)
	# Hormiga desde la oleada 4.
	if w >= 4 and hormiga_scene != null:
		list.append(hormiga_scene)
	list.shuffle()
	return list


## Factor de velocidad de la oleada `w`: las primeras van más lentas.
func _speed_scale(w: int) -> float:
	if w <= 1:
		return early_speed_scale
	if w <= 2:
		return early_speed_scale + 0.2
	return 1.0


## Suelta el próximo enemigo de la cola en un hexágono del borde.
func _spawn_one() -> void:
	if _queue.is_empty():
		return
	var ring: Array[Vector2i] = hex_grid.get_ring_cells()
	if ring.is_empty():
		return
	var cell: Vector2i = ring[randi() % ring.size()]
	var scene: PackedScene = _queue.pop_back()
	_spawn_at(scene, cell)
	_to_spawn -= 1


## Instancia `scene` en la celda `cell` y lo configura según su tipo.
func _spawn_at(scene: PackedScene, cell: Vector2i) -> void:
	var node: Node2D = scene.instantiate()

	# Los enemigos persiguen a la reina y se cuentan como bajas de la oleada.
	if node is Enemy:
		var enemy: Enemy = node
		enemy.target = queen
		enemy.hex_grid = hex_grid
		enemy.speed *= _speed_scale(wave)
		enemy.died.connect(_on_enemy_died)
		_alive += 1

	node.global_position = hex_grid.world_position_of(cell.x, cell.y)
	add_child(node)


## Cerco de enemigos que se cierra hacia el centro. Hasta la oleada 4 es media
## ronda (semicírculo); desde la 5 el círculo es completo, desde todos los lados.
func _spawn_encirclement(w: int) -> void:
	if enemy_scene == null:
		return
	var ring: Array[Vector2i] = hex_grid.get_ring_cells()
	if ring.is_empty():
		return
	var count: int = mini(6 + w, ring.size())
	# Antes de la oleada 5 el cerco es media ronda (semicírculo); recién en la 5
	# se cierra el círculo completo. Los enemigos entran parejos por un solo lado.
	var span: int = ring.size()
	if w < 5:
		span = ring.size() / 2
		count = maxi(1, count / 2)
	# Ordenamos el anillo por ángulo para que queden parejos alrededor del centro.
	var center: Vector2 = hex_grid.world_position_of(0, 0)
	ring.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var pa: Vector2 = hex_grid.world_position_of(a.x, a.y) - center
		var pb: Vector2 = hex_grid.world_position_of(b.x, b.y) - center
		return pa.angle() < pb.angle())
	for i in count:
		var idx: int = int(round(float(i) * float(span) / float(count))) % span
		_spawn_at(enemy_scene, ring[idx])


## Cuando muere un enemigo de la oleada, contamos la baja.
func _on_enemy_died() -> void:
	_alive -= 1
	if _to_spawn <= 0 and _alive <= 0:
		_wait_timer = time_between_waves
		wave_cleared.emit(wave)
