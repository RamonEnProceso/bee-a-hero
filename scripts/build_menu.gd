class_name BuildMenu
extends Control

## Menú de construcción estilo Bloons TD / Plants vs Zombies:
## tarjetas con nombre, precio y dibujo (placeholder de forma de color).

## Se emite con el tipo elegido (Game.BuildType), o -1 si se deseleccionó.
signal build_selected(type: int)


func _ready() -> void:
	# El menú no debe tragarse los clicks del mapa: deja pasar todo salvo sus botones.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Tarjetas abajo al centro, calculadas con el tamaño de la pantalla.
	var card_w := 130.0
	var card_h := 84.0
	var gap := 12.0
	var count: int = Game.BUILD_DEFS.size()
	var total_w: float = count * card_w + (count - 1) * gap
	var start_x: float = (get_viewport_rect().size.x - total_w) / 2.0
	var y: float = get_viewport_rect().size.y - card_h - 24.0

	# Un ButtonGroup hace que las tarjetas se comporten como radio-botones
	# (seleccionar una deselecciona la otra; re-click deselecciona).
	var group := ButtonGroup.new()
	group.allow_unpress = true

	var i := 0
	for type in Game.BUILD_DEFS:
		var def: Dictionary = Game.BUILD_DEFS[type]
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = group
		btn.custom_minimum_size = Vector2(card_w, card_h)
		btn.position = Vector2(start_x + i * (card_w + gap), y)
		btn.icon = _make_icon(def)
		btn.text = "%s  ($%d)" % [def["name"], def["cost"]]
		btn.add_theme_font_size_override("font_size", 16)
		btn.toggled.connect(_on_card_toggled.bind(type))
		add_child(btn)
		i += 1


func _on_card_toggled(pressed: bool, type: int) -> void:
	build_selected.emit(type if pressed else -1)


## Genera el "dibujo" de una tarjeta: una textura con la forma rellena de color.
func _make_icon(def: Dictionary) -> Texture2D:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center := Vector2(size / 2.0, size / 2.0)
	var r := size / 2.0 - 4.0
	var points := PackedVector2Array()

	match def["shape"]:
		"hex":
			for k in 6:
				var a: float = deg_to_rad(60.0 * k - 30.0)
				points.append(center + Vector2(cos(a), sin(a)) * r)
		"tri":
			points = PackedVector2Array([
				center + Vector2(r, 0.0),
				center + Vector2(-r, r),
				center + Vector2(-r, -r),
			])

	var color: Color = def["color"]
	for y in size:
		for x in size:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), points):
				img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)
