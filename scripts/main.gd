extends Node2D

# Referencias a nodos de la escena.
@onready var hex_grid: HexGrid = $HexGrid
@onready var queen: Queen = $Queen
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var builder_bee: BuilderBee = $BuilderBee
@onready var build_menu: BuildMenu = $UILayer/BuildMenu
@onready var material_label: Label = $UILayer/MaterialLabel
@onready var game_over_label: Label = $UILayer/GameOverLabel
@onready var wave_label: Label = $UILayer/WaveLabel
@onready var wave_banner: Label = $UILayer/WaveBanner
@onready var slots_label: Label = $UILayer/SlotsLabel

## Distancia (en anillos hexagonales) a la que la abeja puede construir.
@export var build_range: int = 2
## Escena de la abeja suicida que se coloca en el anillo defensivo.
@export var suicide_bee_scene: PackedScene
## Radio cúbico del anillo donde se colocan las abejas suicidas (alrededor de la reina).
@export var suicide_bee_ring: int = 2

# Tipo de tarjeta que se está arrastrando desde el menú, o -1 si no.
var dragging_type: int = -1


func _ready() -> void:
	# Reina y abeja protagonista arrancan en el centro (0,0).
	queen.global_position = hex_grid.world_position_of(0, 0)
	builder_bee.global_position = hex_grid.world_position_of(0, 0)
	builder_bee.grid = hex_grid

	spawner.hex_grid = hex_grid
	spawner.queen = queen

	queen.died.connect(_on_queen_died)
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)
	Game.materials_changed.connect(_on_materials_changed)
	Game.slots_changed.connect(_on_slots_changed)

	_spawn_suicide_bees()

	_on_materials_changed(Game.materials)
	_on_slots_changed(Game.slots_used(), Game.slot_capacity)


func _unhandled_input(event: InputEvent) -> void:
	# Drag & drop de construcción: agarrar una tarjeta arriba y soltar sobre el panal.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var type: int = build_menu.card_at(event.position)
			if type >= 0 and Game.can_afford(Game.BUILD_DEFS[type]["cost"]):
				dragging_type = type
				_update_drag_preview()
		else:
			if dragging_type >= 0:
				var world: Vector2 = hex_grid.get_global_mouse_position()
				_try_build(dragging_type, hex_grid.cell_at_world(world))
				_end_drag()
	elif event is InputEventMouseMotion and dragging_type >= 0:
		_update_drag_preview()


## Actualiza la vista previa: círculo de rango + celda destino + fantasma.
func _update_drag_preview() -> void:
	var world: Vector2 = hex_grid.get_global_mouse_position()
	var cell: Vector2i = hex_grid.cell_at_world(world)

	hex_grid.show_build_range = true
	hex_grid.build_center = builder_bee.global_position
	hex_grid.build_range_px = build_range * hex_grid.hex_size * sqrt(3.0)
	hex_grid.preview_mouse_world = world
	hex_grid.preview_cell = cell
	hex_grid.preview_type = dragging_type
	hex_grid.preview_valid = _can_build(dragging_type, cell)
	hex_grid.preview_texture = Art.build_icon(dragging_type)
	hex_grid.queue_redraw()


func _end_drag() -> void:
	dragging_type = -1
	hex_grid.show_build_range = false
	hex_grid.preview_texture = null
	hex_grid.preview_type = -1
	hex_grid.queue_redraw()


func _can_build(type: int, cell: Vector2i) -> bool:
	if type < 0:
		return false
	var def: Dictionary = Game.BUILD_DEFS[type]
	if not Game.can_afford(def["cost"]):
		return false
	if not hex_grid.can_place_build(type, cell):
		return false
	# Sin slots libres no se pueden colocar más abejas (torres o aliados).
	if not Game.has_slots(Game.slot_cost(type)):
		return false
	# Cercanía a la abeja y no sobre ella.
	var bee_cell: Vector2i = hex_grid.cell_at_world(builder_bee.global_position)
	if cell == bee_cell:
		return false
	if hex_grid.cube_distance(bee_cell, cell) > build_range:
		return false
	return true


func _try_build(type: int, cell: Vector2i) -> void:
	if not _can_build(type, cell):
		return
	var def: Dictionary = Game.BUILD_DEFS[type]
	var built_node: Node2D = hex_grid.build(type, cell)
	if built_node != null:
		Game.spend(def["cost"])
		# Las torres (y aliados) ocupan slots de abeja; las paredes no.
		var cost: int = Game.slot_cost(type)
		if cost > 0:
			Game.register_slotted(built_node, cost)
		# Feedback: ráfaga de partículas al colocar.
		Fx.burst(self, built_node.global_position)


## Coloca un anillo de abejas suicidas alrededor de la reina, cada una mirando hacia afuera.
func _spawn_suicide_bees() -> void:
	if suicide_bee_scene == null:
		return
	var center: Vector2 = hex_grid.world_position_of(0, 0)
	for cell in hex_grid.get_ring_cells(suicide_bee_ring):
		var b: SuicideBee = suicide_bee_scene.instantiate()
		var pos: Vector2 = hex_grid.world_position_of(cell.x, cell.y)
		b.direction = (pos - center).normalized()  # contraria al centro
		add_child(b)
		b.global_position = pos


func _on_materials_changed(_value: int) -> void:
	material_label.text = "Miel: %d" % Game.materials
	build_menu.queue_redraw()  # actualiza qué tarjetas se ven asequibles


## Actualiza el contador de abejas colocadas / capacidad.
func _on_slots_changed(used: int, capacity: int) -> void:
	slots_label.text = "Abejas: %d/%d" % [used, capacity]
	build_menu.queue_redraw()  # actualiza el brillo de las tarjetas


func _on_wave_started(wave: int) -> void:
	wave_label.text = "Oleada %d" % wave
	_announce_wave("Oleada %d" % wave)


## Al terminar una oleada avanzamos las construcciones y damos recompensas.
func _on_wave_cleared(_wave: int) -> void:
	for node in get_tree().get_nodes_in_group("buildings"):
		if node is Building:
			node.on_wave_cleared()


## Muestra el nombre de la oleada en grande al centro: aparece rápido y se va con un fade lento.
func _announce_wave(text: String) -> void:
	wave_banner.text = text
	wave_banner.pivot_offset = wave_banner.size / 2.0
	wave_banner.modulate.a = 0.0
	wave_banner.scale = Vector2(0.8, 0.8)
	wave_banner.visible = true

	var tw := create_tween()
	# Aparece rápido (pop + fade in).
	tw.tween_property(wave_banner, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(wave_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Se mantiene un momento y desaparece lento.
	tw.tween_interval(1.0)
	tw.tween_property(wave_banner, "modulate:a", 0.0, 1.2)
	tw.tween_callback(func() -> void: wave_banner.visible = false)


func _on_queen_died() -> void:
	game_over_label.visible = true
	spawner.set_process(false)
	get_tree().paused = true
