extends Node2D

# Referencias a nodos de la escena.
@onready var hex_grid: HexGrid = $HexGrid
@onready var queen: Queen = $Queen
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var builder_bee: BuilderBee = $BuilderBee
@onready var build_menu: BuildMenu = $UILayer/BuildMenu
@onready var material_label: Label = $UILayer/MaterialLabel
@onready var game_over_label: Label = $UILayer/GameOverLabel

## Distancia (en anillos hexagonales) a la que la abeja puede construir.
@export var build_range: int = 2

# -1 = nada seleccionado; si no, un valor de Game.BuildType.
var selected_type: int = -1


func _ready() -> void:
	# Reina y abeja protagonista arrancan en el centro (0,0).
	queen.global_position = hex_grid.world_position_of(0, 0)
	builder_bee.global_position = hex_grid.world_position_of(0, 0)
	builder_bee.grid = hex_grid

	spawner.hex_grid = hex_grid
	spawner.queen = queen

	queen.died.connect(_on_queen_died)
	hex_grid.cell_clicked.connect(_on_cell_clicked)
	build_menu.build_selected.connect(_on_build_selected)
	Game.materials_changed.connect(_on_materials_changed)

	_on_materials_changed(Game.materials)


func _on_build_selected(type: int) -> void:
	selected_type = type


func _on_materials_changed(value: int) -> void:
	material_label.text = "Miel: %d" % value


func _on_cell_clicked(cell: Vector2i) -> void:
	if selected_type < 0:
		return  # no hay nada seleccionado en el menú

	var def: Dictionary = Game.BUILD_DEFS[selected_type]
	if not Game.can_afford(def["cost"]):
		return  # sin material suficiente

	# Regla de proximidad: la celda debe estar cerca de la abeja y no sobre ella.
	var bee_cell: Vector2i = hex_grid.cell_at_world(builder_bee.global_position)
	if cell == bee_cell:
		return  # no construir sobre la abeja
	if hex_grid.cube_distance(bee_cell, cell) > build_range:
		return  # demasiado lejos de la abeja

	var built: bool = false
	if selected_type == Game.BuildType.WALL:
		built = hex_grid.build_wall(cell) != null
	elif selected_type == Game.BuildType.TOWER:
		built = hex_grid.build_tower(cell) != null

	if built:
		Game.spend(def["cost"])


func _on_queen_died() -> void:
	game_over_label.visible = true
	spawner.set_process(false)
	get_tree().paused = true
