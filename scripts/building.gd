class_name Building
extends Node2D

## Edificio: ocupa un panal de 7 hexágonos y habilita slots de abejas-torre.
## Mientras se construye (build_rounds > 0) ocupa sus celdas pero no se puede
## atacar. Al terminarse (o al instante si build_rounds == 0) suma slots y pasa
## a dar su recompensa cada oleada. Al romperse resta los slots.

## Vida del edificio (1,5 veces un muro normal de 5 hp).
@export var max_health: int = 8
## Cuántos slots de abeja suma al terminarse (y restará al destruirse).
@export var slots_granted: int = 3
## Rondas que tarda en construirse (0 = se construye al instante).
@export var build_rounds: int = 0

# Referencia a la grilla dueña (para avisarle cuando se rompe).
var grid: HexGrid
# La celda "ancla" del edificio (el centro del panal de 7).
var cell: Vector2i
# Las 7 celdas que ocupa.
var cells: Array[Vector2i] = []
# Tamaño de hexágono; lo asigna la grilla al construir.
var hex_size: float = 32.0

var health: int
## true cuando ya está terminado (o si es instantáneo).
var built: bool = true
# Rondas que faltan para terminar la construcción.
var _construction_left: int = 0
var _hit_tween: Tween
# Nodos de la vista de obra (indicador, conos y mazo): se crean solo si el edificio
# tarda rondas en construirse y se liberan al terminarse.
var _indicator: Sprite2D
var _cones: Array[Sprite2D] = []
var _mallet: Sprite2D
var _indicator_tween: Tween
var _mallet_tween: Tween
var _squash_tween: Tween
## Escala de todos los elementos de obra (1/3 del tamaño de las texturas).
const CONSTRUCTION_SCALE := 0.33
## Posiciones de los 3 conos (esquina inferior izquierda, centro abajo y derecha).
## En unidades de hex_size, medidas desde el centro del edificio.
const CONE_OFFSETS := [
	Vector2(-1.2, 0.7),
	Vector2(0.0, 1.4),
	Vector2(1.2, 0.7),
]
## Posición del pivote del mazo (el mango) en unidades de hex_size.
const MALLET_PIVOT := Vector2(1.4, 0.2)
@onready var sprite: Sprite2D = $Sprite2D

## Tipo de construcción (para leer costo de venta y stats de mejora).
@export var build_type: int = 5  # Game.BuildType.BASE
## Nivel de mejora actual (1 a 3).
var level: int = 1
## Etiqueta que muestra el nivel sobre el edificio (solo nivel 2 y 3).
var _level_label: Label


func _ready() -> void:
	health = max_health
	sprite.texture = _texture()
	add_to_group("buildings")
	Fx.squash(sprite)
	_refresh_level_indicator()
	_construction_left = build_rounds
	if build_rounds <= 0:
		_finish_construction()
	else:
		built = false
		sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
		_spawn_construction_visuals()


## Marca el edificio como terminado: suma slots y recupera su color.
func _finish_construction() -> void:
	built = true
	sprite.modulate = Color.WHITE
	_clear_construction_visuals()
	Fx.squash(sprite)
	Game.increase_capacity(slots_granted)
	# Feedback: sonido y ráfaga de partículas (momento de "desbloqueo").
	Sfx.ding()
	Fx.burst(get_parent(), global_position, Color(1.0, 0.85, 0.4), 16)


## Hook al final de cada oleada: si está en obra, avanza; si ya está listo, da su recompensa.
func on_wave_cleared() -> void:
	if not built:
		_construction_left -= 1
		if _construction_left <= 0:
			_finish_construction()
		return
	_reward()


## Recompensa al terminar cada oleada (las subclases la sobrescriben).
func _reward() -> void:
	pass


## Textura del edificio (cada subtipo devuelve la suya).
func _texture() -> Texture2D:
	return Art.building()


## Crea los tres elementos de la obra (indicador, cono y mazo) mientras el edificio
## se construye. Se liberan al terminar la construcción.
func _spawn_construction_visuals() -> void:
	# Indicador en el centro: late creciendo y achicándose (a escala chica).
	_indicator = Sprite2D.new()
	_indicator.texture = load("res://textures/ConstruccionIndicador.png")
	_indicator.scale = Vector2(CONSTRUCTION_SCALE, CONSTRUCTION_SCALE)
	add_child(_indicator)
	_start_indicator_pulse()

	# Tres conos dentro del sprite, en la parte de abajo: centro y dos esquinas.
	for off in CONE_OFFSETS:
		var cone := Sprite2D.new()
		cone.texture = load("res://textures/ConstruccionCono.png")
		cone.scale = Vector2(CONSTRUCTION_SCALE, CONSTRUCTION_SCALE)
		cone.position = off * hex_size
		add_child(cone)
		_cones.append(cone)

	# Mazo a la derecha, pivotando desde el mango (abajo-derecha); golpea en bucle.
	_mallet = Sprite2D.new()
	_mallet.texture = load("res://textures/ConstruccionMazo.png")
	_mallet.scale = Vector2(CONSTRUCTION_SCALE, CONSTRUCTION_SCALE)
	_mallet.centered = false
	_mallet.offset = Vector2(-64.0, -64.0)  # el mango termina en la esquina inferior-derecha
	_mallet.position = MALLET_PIVOT * hex_size
	add_child(_mallet)
	_start_mallet_swing()


## Latido del indicador: crece y se achica de a poco, en bucle.
func _start_indicator_pulse() -> void:
	# Late alrededor de su escala base (chica): crece y se achica de a poco.
	var lo := CONSTRUCTION_SCALE * 0.8
	var hi := CONSTRUCTION_SCALE * 1.2
	_indicator.scale = Vector2(lo, lo)
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(_indicator, "scale", Vector2(hi, hi), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_indicator_tween.tween_property(_indicator, "scale", Vector2(lo, lo), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Balanceo del mazo: baja golpeando, el edificio se aplasta y vuelve a subir.
func _start_mallet_swing() -> void:
	_mallet.rotation = 0.4  # arranca levantado (~23°)
	_mallet_tween = create_tween().set_loops()
	_mallet_tween.tween_property(_mallet, "rotation", -1.1, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_mallet_tween.tween_callback(_on_mallet_strike)
	_mallet_tween.tween_property(_mallet, "rotation", 0.4, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_mallet_tween.tween_interval(0.25)


## Al impactar el mazo, el edificio se aplasta un poco y vuelve a su tamaño.
func _on_mallet_strike() -> void:
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	sprite.scale = Vector2.ONE
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", Vector2(0.9, 1.1), 0.06)
	_squash_tween.tween_property(sprite, "scale", Vector2.ONE, 0.12)


## Detiene y libera los elementos de la obra al terminar la construcción.
func _clear_construction_visuals() -> void:
	if _indicator_tween != null and _indicator_tween.is_valid():
		_indicator_tween.kill()
	if _mallet_tween != null and _mallet_tween.is_valid():
		_mallet_tween.kill()
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	if is_instance_valid(_indicator):
		_indicator.queue_free()
	for cone in _cones:
		if is_instance_valid(cone):
			cone.queue_free()
	_cones.clear()
	if is_instance_valid(_mallet):
		_mallet.queue_free()


## Resta vida al edificio; en obra no se puede atacar.
func take_damage(amount: int, _attacker: Enemy = null) -> void:
	if not built:
		return
	health = maxi(0, health - amount)
	_shake()
	if health <= 0:
		die()


## Vibra al recibir un golpe (igual que las paredes).
func _shake() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	sprite.position = Vector2.ZERO
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "position", Vector2(3.0, 0.0), 0.035)
	_hit_tween.tween_property(sprite, "position", Vector2(-3.0, 0.0), 0.035)
	_hit_tween.tween_property(sprite, "position", Vector2.ZERO, 0.035)


## Al destruirse (por un enemigo) libera celdas y slots, sacudiendo la cámara.
func die() -> void:
	_teardown(true)


## Retira el edificio de la grilla y libera sus slots (LIFO). Si `shake_cam`
## es true sacude la cámara (cuando lo destruye un enemigo, no al venderlo).
func _teardown(shake_cam: bool) -> void:
	grid.remove_building(self)
	var removed: Array[Node] = Game.decrease_capacity(slots_granted)
	for node in removed:
		if node is Tower and is_instance_valid(node):
			node.die()
		elif is_instance_valid(node):
			node.queue_free()
	if shake_cam:
		Fx.shake(get_viewport().get_camera_2d())
	queue_free()


## Nombre para el menú contextual.
func display_name() -> String:
	return Game.BUILD_DEFS[build_type]["name"]


## ¿Este edificio se puede mejorar?
func is_upgradable() -> bool:
	return Game.is_upgradable(build_type)


## Costo para pasar al siguiente nivel (0 si está al máximo).
func upgrade_cost() -> int:
	return Game.upgrade_cost(build_type, level)


## ¿Se puede mejorar ahora (hay nivel disponible y miel suficiente)?
func can_upgrade() -> bool:
	return level < Game.max_level(build_type) and Game.can_afford(upgrade_cost())


## Miel que devuelve vender este edificio.
func sell_value() -> int:
	return Game.sell_value(build_type, level)


## Mejora al siguiente nivel: descuenta miel, sube de nivel, aplica stats y
## refresca el indicador. Devuelve true si se mejoró.
func upgrade() -> bool:
	if not can_upgrade():
		return false
	Game.spend(upgrade_cost())
	level += 1
	_apply_level_stats()
	_refresh_level_indicator()
	Sfx.upgrade()
	Fx.burst(get_parent(), global_position, Color(0.5, 1.0, 0.7), 18)
	return true


## Aplica los stats del nivel actual. El edificio base suma la diferencia de
## slots; la guardería y la cultivadora no cambian stats acá (leen su nivel al
## dar la recompensa).
func _apply_level_stats() -> void:
	var new_slots: int = Game.level_stat(build_type, level, "slots", slots_granted)
	var delta: int = new_slots - slots_granted
	slots_granted = new_slots
	Game.increase_capacity(delta)


## Vende el edificio: devuelve 3/8 de lo invertido y lo retira.
func sell() -> void:
	var refund: int = sell_value()
	Game.gain(refund)
	Sfx.coin()
	Fx.float_text(get_parent(), global_position, "+%d" % refund)
	_teardown(false)


## Muestra el nivel actual sobre el edificio (nivel 1 no muestra nada).
func _refresh_level_indicator() -> void:
	if level <= 1:
		if _level_label != null:
			_level_label.queue_free()
			_level_label = null
		return
	if _level_label == null:
		_level_label = Label.new()
		_level_label.z_index = 30
		_level_label.add_theme_font_size_override("font_size", 16)
		_level_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
		_level_label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.05))
		_level_label.add_theme_constant_override("outline_size", 5)
		add_child(_level_label)
	_level_label.text = str(level)
	_level_label.position = Vector2(-10.0, -hex_size * 2.0)
