extends Node2D

# Referencias a los nodos de la escena (se resuelven al cargar la escena).
@onready var hex_grid: HexGrid = $HexGrid
@onready var queen: Queen = $Queen
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var game_over_label: Label = $UILayer/GameOverLabel


func _ready() -> void:
	# La reina se coloca en el hexágono central (0,0), en coordenadas del mundo.
	queen.global_position = hex_grid.world_position_of(0, 0)

	# Le damos al spawner lo que necesita para trabajar.
	spawner.hex_grid = hex_grid
	spawner.queen = queen

	# Cuando la reina muere, perdimos.
	queen.died.connect(_on_queen_died)


func _on_queen_died() -> void:
	game_over_label.visible = true
	spawner.set_process(false)
	get_tree().paused = true
