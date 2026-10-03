class_name EnemySpawner
extends Node2D

## Escena del enemigo a instanciar.
@export var enemy_scene: PackedScene
## Segundos entre un enemigo y el siguiente.
@export var spawn_interval: float = 2.5

# Referencias que Main completa en _ready (la grilla y la reina).
var hex_grid: HexGrid
var queen: Queen

# Contador interno; arranca bajo para que el primer spawn sea casi inmediato.
var timer: float = 0.5


func _process(delta: float) -> void:
	# Si Main todavía no inyectó las referencias, no hacemos nada.
	if queen == null or hex_grid == null:
		return
	timer -= delta
	if timer <= 0.0:
		timer = spawn_interval
		_spawn_enemy()


## Crea una avispa en un hexágono del borde y le dice a quién perseguir.
func _spawn_enemy() -> void:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.target = queen
	enemy.hex_grid = hex_grid

	var ring: Array[Vector2i] = hex_grid.get_ring_cells()
	var cell: Vector2i = ring[randi() % ring.size()]
	enemy.global_position = hex_grid.world_position_of(cell.x, cell.y)

	add_child(enemy)
