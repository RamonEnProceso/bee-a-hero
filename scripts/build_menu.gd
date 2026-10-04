class_name BuildMenu
extends Control

## Menú de compra estilo panal: tarjetas hexagonales escalonadas a la derecha
## Cada celda muestra el sprite del objeto y, abajo, el icono de miel + el precio.
## No usa botones: main.gd hace el drag con card_at().
## También dibuja tooltips y resalta la Base y la Torre gratuita.

const TOOLTIPS := {
	Game.BuildType.WALL: "Recibe golpes",
	Game.BuildType.REINFORCED: "Recibe más golpes",
	Game.BuildType.TRAP: "Daña al que la toca",
	Game.BuildType.TOWER: "Dispara a los enemigos",
	Game.BuildType.DOUBLE_TOWER: "Dispara el doble de rápido",
	Game.BuildType.BASE: "Desbloquea 3 abejas más",
	Game.BuildType.GUARDERIA: "Torre gratis para colocar por oleada",
	Game.BuildType.CULTIVADORA: "Genera 100 de miel por oleada",
	Game.BuildType.GUARDIA: "Pelea cuerpo a cuerpo",
	Game.BuildType.LONG_RANGE: "Dispara lejos, lento",
}


# ============================================================
# GEOMETRÍA DEL PANAL
# ============================================================

const HEX_R := 45.0

## Cuántas celdas tiene cada fila (tiene que sumar BUILD_DEFS.size() = 10).
const ROW_COUNTS := [2, 2, 2, 2, 2]

## Corrimiento horizontal de cada fila, en fracción de ancho de hexágono.
## 0.5 = media celda a la derecha. Esto es lo que genera el encastre.
const ROW_SHIFTS := [0.0, 0.5, 0.0, 0.5, 0.0]

const SPRITE_SCALE := 0.9
const SPRITE_OFFSET_Y := -0.25
const TAG_OFFSET_Y := 0.4
const MARGIN_RIGHT := 26.0

# ============================================================
# PALETA
# ============================================================

const HEX_FILL := Color(0.224, 0.169, 0.067, 0.74)
const HEX_STROKE := Color(0.655, 0.392, 0.161)
const HONEY := Color(0.949, 0.855, 0.365)

## Icono de miel del HUD.
const HONEY_ICON := preload("res://textures/Miel_particula.png")


# ============================================================
# ESTADO
# ============================================================

## type -> centro del hexágono.
var _cards: Dictionary = {}

var _hovered: int = -1


func _ready() -> void:
	# El menú deja pasar los clicks.
	# main.gd interpreta el drag mediante card_at().
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_layout_cards()


func _process(_delta: float) -> void:
	# Rastreamos el mouse para el tooltip.
	var t: int = card_at(get_viewport().get_mouse_position())

	var needs_redraw := t != _hovered

	_hovered = t

	if _base_needs_glow():
		needs_redraw = true

	# La Torre también late mientras haya una gratis.
	if Game.has_free_tower():
		needs_redraw = true

	if needs_redraw:
		queue_redraw()


# ============================================================
# DISTRIBUCIÓN DEL PANAL
# ============================================================

## Distribuye las tarjetas en dos columnas escalonadas.
##
## Visualmente:
##
##      HEX
##          HEX
##      HEX
##          HEX
##      HEX
##          HEX
##
## Las 10 tarjetas forman 5 filas.
func _layout_cards() -> void:
	var w := _hex_width()
	var row_step := HEX_R * 1.5
	var rows := ROW_COUNTS.size()

	# Ancho del panal = la fila más ancha (contando su corrimiento).
	var menu_w := 0.0
	for r in rows:
		var n: int = ROW_COUNTS[r]
		var shift: float = ROW_SHIFTS[r]
		menu_w = maxf(menu_w, (n + shift) * w)

	var menu_h := (rows - 1) * row_step + _hex_height()

	# Centro de la primera celda de una fila sin corrimiento.
	var origin := Vector2(
		get_viewport_rect().size.x - MARGIN_RIGHT - menu_w + w / 2.0,
		(get_viewport_rect().size.y - menu_h) / 2.0 + _hex_height() / 2.0
	)

	_cards.clear()
	var types := Game.BUILD_DEFS.keys()
	var i := 0

	for r in rows:
		var n: int = ROW_COUNTS[r]
		var shift: float = ROW_SHIFTS[r]
		for c in n:
			if i >= types.size():
				break
			_cards[types[i]] = origin + Vector2(
				(c + shift) * w,
				r * row_step
			)
			i += 1

	if i < types.size():
		push_warning("BuildMenu: faltan slots para %d tarjetas" % (types.size() - i))

	queue_redraw()

# ============================================================
# HIT TEST
# ============================================================

## Devuelve el tipo de tarjeta bajo `pos`.
## -1 si no hay ninguna.
func card_at(pos: Vector2) -> int:

	for type in _cards:

		var center: Vector2 = _cards[type]

		if Geometry2D.is_point_in_polygon(
			pos,
			_hex_points(center)
		):
			return type

		if _tag_rect(center).has_point(pos):
			return type

	return -1


# ============================================================
# BASE
# ============================================================

func _base_needs_glow() -> bool:
	return not Game.has_slot() or Game.slot_capacity == 1


# ============================================================
# DIBUJADO
# ============================================================

## ¿Esta tarjeta está brillando ahora mismo?
func _is_highlighted(type: int) -> bool:
	return (
		(type == Game.BuildType.BASE and _base_needs_glow())
		or (type == Game.BuildType.TOWER and Game.has_free_tower())
	)


## Orden de dibujado: primero las normales, al final las resaltadas.
func _draw_order() -> Array:
	var normal: Array = []
	var highlighted: Array = []

	for type in _cards:
		if _is_highlighted(type):
			highlighted.append(type)
		else:
			normal.append(type)

	return normal + highlighted

func _draw() -> void:

	var font := ThemeDB.fallback_font

	var pulse: float = (
		0.5
		+ 0.5 * sin(
			float(Time.get_ticks_msec()) / 300.0
		)
	)


	for type in _draw_order():

		var center: Vector2 = _cards[type]

		var cost: int = Game.BUILD_DEFS[type]["cost"]

		var is_free: bool = (
			type == Game.BuildType.TOWER
			and Game.has_free_tower()
		)

		var afford: bool = (
			is_free
			or Game.can_afford(cost)
		)

		var out_of_slots: bool = not Game.has_slots(
			Game.slot_cost(type)
		)

		var dim: bool = (
			not afford
			or out_of_slots
		)

		var pts := _hex_points(center)


		# ----------------------------------------------------
		# CELDA
		# ----------------------------------------------------

		draw_polygon(
			pts,
			PackedColorArray([HEX_FILL])
		)


		# ----------------------------------------------------
		# BORDE
		# ----------------------------------------------------

		if type == Game.BuildType.BASE and _base_needs_glow():

			var glow := Color(1.0, 0.85, 0.4).lerp(
				Color(1.0, 1.0, 0.95),
				pulse
			)

			_draw_hex_outline(
				pts,
				glow,
				6.0
			)

		elif type == Game.BuildType.TOWER and Game.has_free_tower():

			var glow := Color(0.35, 0.9, 0.45).lerp(
				Color(0.8, 1.0, 0.85),
				pulse
			)

			_draw_hex_outline(
				pts,
				glow,
				6.0
			)

		else:

			_draw_hex_outline(
				pts,
				HEX_STROKE,
				5.0
			)


		# ----------------------------------------------------
		# SPRITE
		# ----------------------------------------------------

		var tex: Texture2D = Art.build_icon(type)

		draw_texture_rect(
			tex,
			_sprite_rect(center),
			false,
			Color(
				1,
				1,
				1,
				1.0 if not dim else 0.35
			)
		)


		# ----------------------------------------------------
		# PRECIO
		# ----------------------------------------------------

		_draw_price(
			font,
			center,
			cost,
			is_free,
			afford,
			dim
		)


	# --------------------------------------------------------
	# TOOLTIP
	# --------------------------------------------------------

	if _hovered >= 0 and TOOLTIPS.has(_hovered):

		var text: String = "%s: %s" % [
			Game.BUILD_DEFS[_hovered]["name"],
			TOOLTIPS[_hovered]
		]

		_draw_tooltip(
			font,
			_cards[_hovered],
			text
		)


# ============================================================
# HEXÁGONO
# ============================================================

func _hex_points(center: Vector2) -> PackedVector2Array:

	var pts := PackedVector2Array()

	for i in 6:

		var a := deg_to_rad(
			60.0 * i - 30.0
		)

		pts.append(
			center
			+ Vector2(
				cos(a),
				sin(a)
			) * HEX_R
		)

	return pts


func _draw_hex_outline(
	pts: PackedVector2Array,
	color: Color,
	width: float
) -> void:

	var closed := PackedVector2Array(pts)

	closed.append(pts[0])

	draw_polyline(
		closed,
		color,
		width,
		true
	)


func _hex_width() -> float:
	return HEX_R * sqrt(3.0)


func _hex_height() -> float:
	return HEX_R * 2.0


# ============================================================
# SPRITE
# ============================================================

func _sprite_rect(center: Vector2) -> Rect2:

	var size := HEX_R * SPRITE_SCALE

	return Rect2(
		center
			+ Vector2(
				-size / 2.0,
				-size / 2.0
				+ SPRITE_OFFSET_Y * HEX_R
			),
		Vector2(
			size,
			size
		)
	)


# ============================================================
# PRECIO
# ============================================================

func _tag_rect(center: Vector2) -> Rect2:

	var w := HEX_R * 1.35
	var h := HEX_R * 0.31

	var c := center + Vector2(
		0.0,
		TAG_OFFSET_Y * HEX_R
	)

	return Rect2(
		c - Vector2(
			w / 2.0,
			h / 2.0
		),
		Vector2(
			w,
			h
		)
	)


func _draw_price(
	font: Font,
	center: Vector2,
	cost: int,
	is_free: bool,
	afford: bool,
	dim: bool
) -> void:

	var text := (
		"GRATIS"
		if is_free
		else str(cost)
	)

	var text_color := (
		Color(0.3, 0.85, 0.4)
		if is_free
		else (
			HONEY
			if afford
			else Color(0.8, 0.3, 0.3)
		)
	)

	var fs := int(
		HEX_R * 0.40
	)

	var icon_size := float(fs)

	var gap := maxf(
		3.0,
		float(fs) * 0.25
	)

	var text_w := font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs
	).x

	var total_w := (
		icon_size
		+ gap
		+ text_w
	)

	var base_y := (
		center.y
		+ TAG_OFFSET_Y * HEX_R
	)

	var start_x := (
		center.x
		- total_w / 2.0
	)


	# Icono de miel.
	var icon_rect := Rect2(
		Vector2(
			start_x,
			base_y - icon_size / 2.0
		),
		Vector2(
			icon_size,
			icon_size
		)
	)

	draw_texture_rect(
		HONEY_ICON,
		icon_rect,
		false,
		Color(
			1,
			1,
			1,
			1.0 if not dim else 0.6
		)
	)


	# Texto.
	var baseline := (
		base_y
		+ (
			font.get_ascent(fs)
			- font.get_descent(fs)
		) * 0.5
	)

	var pos := Vector2(
		start_x + icon_size + gap,
		baseline
	)


	# Contorno.
	draw_string_outline(
		font,
		pos,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		9,
		Color(0.35, 0.1, 0.05)
	)


	# Texto.
	draw_string(
		font,
		pos,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		text_color
	)


# ============================================================
# TOOLTIP
# ============================================================

const TOOLTIP_FONT_SIZE := 14
const TOOLTIP_GAP := 8.0

func _draw_tooltip(
	font: Font,
	center: Vector2,
	text: String
) -> void:

	var fs := TOOLTIP_FONT_SIZE
	var pad := Vector2(10.0, 6.0)

	# Tamaño real del texto (ancho Y alto).
	var text_size := font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs
	)

	# La caja se adapta al texto + el margen interno.
	var box_size := text_size + pad * 2.0

	# Pegada al borde izquierdo del hexágono, con un hueco.
	var box := Rect2(
		Vector2(
			center.x - _hex_width() / 2.0 - TOOLTIP_GAP - box_size.x,
			center.y - box_size.y / 2.0
		),
		box_size
	)

	draw_rect(box, Color(0.05, 0.04, 0.02, 0.95), true)
	draw_rect(box, Color(1.0, 0.85, 0.4, 0.7), false, 1.5)

	# Línea base para que el texto quede centrado en la caja.
	var baseline := (
		box.position.y
		+ box_size.y / 2.0
		+ (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	)

	draw_string(
		font,
		Vector2(box.position.x + pad.x, baseline),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		Color(1, 1, 1)
	)