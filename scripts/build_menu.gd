class_name BuildMenu
extends Control

## Menú de tarjetas estilo Bloons TD6: dos columnas en el borde derecho.
## Cada tarjeta muestra el dibujo arriba, nombre y precio abajo.
## No usa botones: dibuja las tarjetas y main.gd hace el drag con card_at().
## También dibuja tooltips y resalta la tarjeta de la Base cuando faltan slots.

## Descripción de cada tarjeta (se muestra en el tooltip al pasar el mouse).
const TOOLTIPS := {
	Game.BuildType.WALL: "Recibe golpes",
	Game.BuildType.REINFORCED: "Recibe más golpes",
	Game.BuildType.TRAP: "Daña al que la toca",
	Game.BuildType.TOWER: "Dispara a los enemigos",
	Game.BuildType.DOUBLE_TOWER: "Dispara el doble de rápido",
	Game.BuildType.BIG_TOWER: "Tiros fuertes de largo alcance",
	Game.BuildType.BASE: "Desbloquea 3 abejas más",
	Game.BuildType.GUARDERIA: "Regala una torre por oleada",
	Game.BuildType.CULTIVADORA: "Genera 100 de miel por oleada",
}

var _cards: Dictionary = {}  # type -> Rect2
var _hovered: int = -1


func _ready() -> void:
	# El menú deja pasar los clicks (solo main.gd los interpreta).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_cards()


func _process(_delta: float) -> void:
	# Rastreamos el mouse para el tooltip y repintamos mientras la Base pulse.
	var t: int = card_at(get_viewport().get_mouse_position())
	var needs_redraw := t != _hovered
	_hovered = t
	if _base_needs_glow():
		needs_redraw = true
	if needs_redraw:
		queue_redraw()


## Distribuye las tarjetas en dos columnas (4 filas para 7 tarjetas).
func _layout_cards() -> void:
	var card_w := 120.0
	var card_h := 88.0
	var gap := 8.0
	var margin := 14.0
	var cols := 2
	var x0: float = get_viewport_rect().size.x - margin - cols * card_w - (cols - 1) * gap
	var y0: float = 14.0
	var i := 0
	for type in Game.BUILD_DEFS:
		var col: int = i % cols
		var row: int = int(i / cols)
		var pos := Vector2(x0 + col * (card_w + gap), y0 + row * (card_h + gap))
		_cards[type] = Rect2(pos, Vector2(card_w, card_h))
		i += 1
	queue_redraw()


## Devuelve el tipo de tarjeta bajo `pos` (coordenadas de pantalla), o -1 si ninguna.
func card_at(pos: Vector2) -> int:
	for type in _cards:
		if _cards[type].has_point(pos):
			return type
	return -1


## ¿La tarjeta de la Base tiene que brillar para guiar al jugador?
## Sí cuando no quedan slots libres, o cuando todavía no se amplió la capacidad inicial.
func _base_needs_glow() -> bool:
	return not Game.has_slot() or Game.slot_capacity == 1


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 300.0)

	for type in _cards:
		var r: Rect2 = _cards[type]
		var def: Dictionary = Game.BUILD_DEFS[type]
		var name: String = def["name"]
		var cost: int = def["cost"]
		var afford: bool = Game.can_afford(cost)
		var out_of_slots: bool = Game.consumes_slot(type) and not Game.has_slot()
		var dim: bool = not afford or out_of_slots

		# Fondo de la tarjeta.
		draw_rect(r, Color(0.16, 0.12, 0.06, 0.92), true)

		# Borde: la Base pulsa (más brillante) cuando el jugador necesita construir.
		if type == Game.BuildType.BASE and _base_needs_glow():
			var glow := Color(1.0, 0.85, 0.4).lerp(Color(1.0, 1.0, 0.95), pulse)
			draw_rect(r, glow, false, 4.0)
		else:
			draw_rect(r, Color(1.0, 0.85, 0.4, 0.5), false, 2.0)

		# Dibujo arriba (se atenúa si no se puede usar).
		var tex: Texture2D = Art.build_icon(type)
		var icon_size := 42.0
		var icon_rect := Rect2(r.position + Vector2((r.size.x - icon_size) / 2.0, 6.0), Vector2(icon_size, icon_size))
		draw_texture_rect(tex, icon_rect, false, Color(1, 1, 1, 1.0 if not dim else 0.35))

		# Nombre y precio abajo (centrados).
		var name_color := Color(1, 1, 1) if not dim else Color(0.55, 0.55, 0.55)
		draw_string(font, Vector2(r.position.x, r.position.y + 54.0), name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, name_color)
		var cost_color := Color(1.0, 0.9, 0.4) if afford else Color(0.7, 0.3, 0.3)
		draw_string(font, Vector2(r.position.x, r.position.y + 72.0), "$%d" % cost, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, cost_color)

	# Tooltip del tipo bajo el mouse (a la izquierda de la tarjeta, para no salirse).
	if _hovered >= 0 and TOOLTIPS.has(_hovered):
		_draw_tooltip(font, _cards[_hovered], TOOLTIPS[_hovered])


## Tooltip chico pegado a la tarjeta con la función exacta.
func _draw_tooltip(font: Font, card: Rect2, text: String) -> void:
	var pad := Vector2(10.0, 6.0)
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var box := Rect2(card.position.x - text_w - pad.x * 2.0 - 8.0, card.position.y + card.size.y * 0.5 - 14.0, text_w + pad.x * 2.0, 28.0)
	draw_rect(box, Color(0.05, 0.04, 0.02, 0.95), true)
	draw_rect(box, Color(1.0, 0.85, 0.4, 0.7), false, 1.5)
	draw_string(font, box.position + pad, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
