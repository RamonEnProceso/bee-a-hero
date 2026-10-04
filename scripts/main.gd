extends Node2D

# Referencias a nodos de la escena.
@onready var hex_grid: HexGrid = $HexGrid
@onready var queen: Queen = $Queen
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var builder_bee: BuilderBee = $BuilderBee
@onready var build_menu: BuildMenu = $UILayer/BuildMenu
@onready var material_label: Label = $UILayer/MaterialLabel/Number
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var wave_label: Label = $UILayer/WaveLabel
@onready var wave_banner: Label = $UILayer/WaveBanner
@onready var slots_label: Label = $UILayer/SlotsLabel
@onready var free_bee_label: Label = $UILayer/FreeBeeLabel
@onready var context_menu: ContextMenu = $UILayer/ContextMenu

## Distancia (en anillos hexagonales) a la que la abeja puede construir.
@export var build_range: int = 2
## Escena de la abeja suicida que se coloca en el anillo defensivo.
@export var suicide_bee_scene: PackedScene
## Radio cúbico del anillo donde se colocan las abejas suicidas (alrededor de la reina).
@export var suicide_bee_ring: int = 2

# Tipo de tarjeta que se está arrastrando desde el menú, o -1 si no.
var dragging_type: int = -1
# Tween del latido de la etiqueta "Abejas gratis".
var _free_tween: Tween


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
	Game.free_towers_changed.connect(_on_free_towers_changed)

	_spawn_suicide_bees()

	_on_materials_changed(Game.materials)
	_on_slots_changed(Game.slots_used(), Game.slot_capacity)
	_on_free_towers_changed(Game.free_towers)


func _unhandled_input(event: InputEvent) -> void:
	# Escape: cierra el menú contextual o abre el menú de pausa.
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not get_tree().paused:
			if context_menu.visible:
				context_menu.hide_menu()
			else:
				pause_menu.open()
			get_viewport().set_input_as_handled()
		return

	# Drag & drop de construcción: agarrar una tarjeta arriba y soltar sobre el panal.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var type: int = build_menu.card_at(event.position)
			if type >= 0 and _affordable(type):
				dragging_type = type
				context_menu.hide_menu()
				_update_drag_preview()
			else:
				# No arrastramos: tocamos una construcción (o un hexágono vacío).
				_select_at(hex_grid.get_global_mouse_position())
		else:
			if dragging_type >= 0:
				var world: Vector2 = hex_grid.get_global_mouse_position()
				_try_build(dragging_type, hex_grid.cell_at_world(world))
				_end_drag()
	elif event is InputEventMouseMotion and dragging_type >= 0:
		_update_drag_preview()


## Al hacer click (sin arrastrar) sobre una construcción muestra su menú;
## sobre un hexágono vacío lo cierra.
func _select_at(world: Vector2) -> void:
	var structure = hex_grid.structure_at(hex_grid.cell_at_world(world))
	if structure != null:
		context_menu.show_for(structure)
	else:
		context_menu.hide_menu()


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


## ¿Se puede pagar `type`? La torre común sale gratis si la guardería entregó una.
func _affordable(type: int) -> bool:
	if type == Game.BuildType.TOWER and Game.has_free_tower():
		return true
	return Game.can_afford(Game.BUILD_DEFS[type]["cost"])


func _can_build(type: int, cell: Vector2i) -> bool:
	if type < 0:
		return false
	var def: Dictionary = Game.BUILD_DEFS[type]
	if not _affordable(type):
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
		# La torre común puede ser gratis si la guardería entregó una (de su nivel).
		var free_lvl := 0
		if type == Game.BuildType.TOWER and Game.has_free_tower():
			free_lvl = Game.consume_free_tower()
		else:
			Game.spend(def["cost"])
		if free_lvl > 0 and built_node is Tower:
			built_node.set_level(free_lvl)
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
	material_label.text = "%d" % Game.materials  # solo el número, el icono está al lado
	build_menu.queue_redraw()  # actualiza qué tarjetas se ven asequibles


## Actualiza el contador de abejas colocadas / capacidad.
func _on_slots_changed(used: int, capacity: int) -> void:
	slots_label.text = "Abejas: %d/%d" % [used, capacity]
	build_menu.queue_redraw()  # actualiza el brillo de las tarjetas


## Actualiza la etiqueta "Abejas gratis" y el menú. Con abejas gratis la
## etiqueta late en dorado para que sea imposible no verla.
func _on_free_towers_changed(count: int) -> void:
	free_bee_label.text = "Abejas gratis: %d" % count
	if count > 0:
		free_bee_label.modulate = Color.WHITE
		_start_free_pulse()
	else:
		_stop_free_pulse()
		free_bee_label.modulate = Color(1, 1, 1, 0.35)
	build_menu.queue_redraw()


## Latido continuo de la etiqueta "Abejas gratis" mientras haya abejas gratis.
func _start_free_pulse() -> void:
	if _free_tween != null and _free_tween.is_valid():
		_free_tween.kill()
	_free_tween = create_tween().set_loops()
	_free_tween.tween_property(free_bee_label, "modulate:a", 0.35, 0.6)
	_free_tween.tween_property(free_bee_label, "modulate:a", 1.0, 0.6)


## Detiene el latido y deja la etiqueta a su transparencia normal.
func _stop_free_pulse() -> void:
	if _free_tween != null and _free_tween.is_valid():
		_free_tween.kill()
	free_bee_label.modulate.a = 1.0


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
	spawner.set_process(false)
	context_menu.hide_menu()
	game_over_screen.show_game_over(spawner.wave)
	get_tree().paused = true
