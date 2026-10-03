class_name BuildMenu
extends Control

## Menú de tarjetas estilo Plants vs Zombies: arriba de la pantalla,
## con el dibujo arriba y el valor (precio) abajo.
## No usa botones: dibuja las tarjetas y main.gd hace el drag con card_at().

var _cards: Dictionary = {}  # type -> Rect2


func _ready() -> void:
	# El menú deja pasar los clicks (solo main.gd los interpreta).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_cards()


func _layout_cards() -> void:
	var card_w := 96.0
	var card_h := 128.0
	var gap := 14.0
	var count: int = Game.BUILD_DEFS.size()
	var total_w: float = count * card_w + (count - 1) * gap
	var x0: float = (get_viewport_rect().size.x - total_w) / 2.0
	var y0: float = 12.0
	var i := 0
	for type in Game.BUILD_DEFS:
		_cards[type] = Rect2(x0 + i * (card_w + gap), y0, card_w, card_h)
		i += 1
	queue_redraw()


## Devuelve el tipo de tarjeta bajo `pos` (coordenadas de pantalla), o -1 si ninguna.
func card_at(pos: Vector2) -> int:
	for type in _cards:
		if _cards[type].has_point(pos):
			return type
	return -1


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for type in _cards:
		var r: Rect2 = _cards[type]
		var def: Dictionary = Game.BUILD_DEFS[type]
		var name: String = def["name"]
		var cost: int = def["cost"]
		var afford: bool = Game.can_afford(cost)

		# Fondo de la tarjeta.
		draw_rect(r, Color(0.16, 0.12, 0.06, 0.92), true)
		draw_rect(r, Color(1.0, 0.85, 0.4, 0.5), false, 2.0)

		# Dibujo arriba.
		var tex: Texture2D = Art.build_icon(type)
		var icon_size := 56.0
		var icon_rect := Rect2(r.position + Vector2((r.size.x - icon_size) / 2.0, 10.0), Vector2(icon_size, icon_size))
		draw_texture_rect(tex, icon_rect, false, Color(1, 1, 1, 1.0 if afford else 0.4))

		# Nombre y precio abajo (centrados).
		var name_color := Color(1, 1, 1) if afford else Color(0.6, 0.6, 0.6)
		draw_string(font, Vector2(r.position.x, r.position.y + 82.0), name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, name_color)
		var cost_color := Color(1.0, 0.9, 0.4) if afford else Color(0.7, 0.3, 0.3)
		draw_string(font, Vector2(r.position.x, r.position.y + 104.0), "$%d" % cost, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, cost_color)
