class_name Art
extends RefCounted

## Genera texturas placeholder para las entidades (sprites editables luego).
## Todas se cachean para generarse UNA sola vez. `preload_all()` las crea todas al inicio
## para evitar cortes de FPS en medio del juego.
## Para poner arte real: reemplazar estos generadores o asignar un PNG al Sprite2D.

static var _cache: Dictionary = {}


## Genera (una sola vez) todas las texturas. Se llama al arrancar el juego.
static func preload_all() -> void:
	queen()
	bee()
	suicide_bee()
	enemy()
	spiral_wasp()
	shooter_wasp()
	enemy_projectile()
	cat_paw()
	bear_paw()
	tower()
	wall()
	reinforced_wall()
	trap()
	double_tower()
	guardia()
	long_range()
	bomb_wasp()
	hormiga()
	polilla()
	egg()
	building()
	guarderia()
	cultivadora()
	projectile()
	pickup()


## Textura para la tarjeta del menú de un tipo construible.
static func build_icon(type: int) -> Texture2D:
	match type:
		Game.BuildType.WALL:
			return wall()
		Game.BuildType.TOWER:
			return tower()
		Game.BuildType.REINFORCED:
			return reinforced_wall()
		Game.BuildType.TRAP:
			return trap()
		Game.BuildType.DOUBLE_TOWER:
			return double_tower()
		Game.BuildType.BASE:
			return building()
		Game.BuildType.GUARDERIA:
			return guarderia()
		Game.BuildType.CULTIVADORA:
			return cultivadora()
		Game.BuildType.GUARDIA:
			return guardia()
		Game.BuildType.LONG_RANGE:
			return long_range()
	return wall()


## Devuelve `base` teñida de dorado según el nivel (1 = igual, 2 = dorado suave,
## 3 = dorado intenso). Así el sprite de cada construcción cambia al mejorar, sin
## necesidad de dibujar un número encima.
static func leveled(base: Texture2D, level: int) -> Texture2D:
	if level <= 1:
		return base
	var img: Image = base.get_image()
	if img == null:
		return base
	var gold := Color(1.0, 0.9, 0.55)
	var amount: float = 0.3 if level == 2 else 0.55
	for y in img.get_height():
		for x in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, c.lerp(gold, amount))
	return ImageTexture.create_from_image(img)


static func queen() -> Texture2D:
	if not _cache.has("queen"):
		_cache["queen"] = _circle(24, Color(1.0, 0.84, 0.25), 64)
	return _cache["queen"]


static func projectile() -> Texture2D:
	if not _cache.has("projectile"):
		_cache["projectile"] = _circle(4, Color(1.0, 0.9, 0.3), 16)
	return _cache["projectile"]


## Gota de miel que suelta el enemigo al morir.
static func pickup() -> Texture2D:
	if not _cache.has("pickup"):
		_cache["pickup"] = _circle(6, Color(1.0, 0.85, 0.2), 16)
	return _cache["pickup"]


static func bee() -> Texture2D:
	if not _cache.has("bee"):
		_cache["bee"] = _bee_texture(32, 10.0)
	return _cache["bee"]


## Abeja suicida: igual pero más grande (se coloca en el anillo defensivo).
static func suicide_bee() -> Texture2D:
	if not _cache.has("suicide_bee"):
		_cache["suicide_bee"] = _bee_texture(48, 15.0)
	return _cache["suicide_bee"]


static func enemy() -> Texture2D:
	if not _cache.has("enemy"):
		var pts := PackedVector2Array([
			Vector2(30, 16), Vector2(4, 4), Vector2(4, 28),
		])
		_cache["enemy"] = _polygon(pts, Color(0.85, 0.15, 0.15), 32)
	return _cache["enemy"]


## Avispa torbellino: igual a la avispa común pero color turquesa (gira en espiral).
static func spiral_wasp() -> Texture2D:
	if not _cache.has("spiral_wasp"):
		var pts := PackedVector2Array([
			Vector2(30, 16), Vector2(4, 4), Vector2(4, 28),
		])
		_cache["spiral_wasp"] = _polygon(pts, Color(0.15, 0.7, 0.65), 32)
	return _cache["spiral_wasp"]


## Avispa tiradora: aguijón más fino y color violeta (dispara aguijones a la reina).
static func shooter_wasp() -> Texture2D:
	if not _cache.has("shooter_wasp"):
		var pts := PackedVector2Array([
			Vector2(30, 16), Vector2(2, 9), Vector2(2, 23),
		])
		_cache["shooter_wasp"] = _polygon(pts, Color(0.75, 0.3, 0.85), 32)
	return _cache["shooter_wasp"]


## Aguijón que dispara la avispa tiradora (pequeño, color naranja).
static func enemy_projectile() -> Texture2D:
	if not _cache.has("enemy_projectile"):
		_cache["enemy_projectile"] = _circle(3, Color(1.0, 0.45, 0.1), 16)
	return _cache["enemy_projectile"]


## Pata de gato: círculo claro (se lleva torres descubiertas).
static func cat_paw() -> Texture2D:
	if not _cache.has("cat_paw"):
		_cache["cat_paw"] = _circle(11, Color(0.78, 0.58, 0.48), 32)
	return _cache["cat_paw"]


## Pata de oso: círculo marrón grande (rompe paredes y roba miel).
static func bear_paw() -> Texture2D:
	if not _cache.has("bear_paw"):
		_cache["bear_paw"] = _circle(15, Color(0.45, 0.3, 0.2), 40)
	return _cache["bear_paw"]


## Avispa bomba: cuerpo oscuro con chispa naranja (explota al morir).
static func bomb_wasp() -> Texture2D:
	if not _cache.has("bomb_wasp"):
		var size := 40
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		_paint_dot(img, 20.0, 20.0, 13.0, Color(0.5, 0.08, 0.08))
		_paint_dot(img, 27.0, 13.0, 4.0, Color(1.0, 0.55, 0.1))
		_cache["bomb_wasp"] = ImageTexture.create_from_image(img)
	return _cache["bomb_wasp"]


## Hormiga: tres segmentos marrones en fila (roba miel y huye).
static func hormiga() -> Texture2D:
	if not _cache.has("hormiga"):
		var size := 40
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var brown := Color(0.35, 0.22, 0.1)
		_paint_dot(img, 12.0, 20.0, 6.0, brown)
		_paint_dot(img, 20.0, 20.0, 5.0, brown)
		_paint_dot(img, 28.0, 20.0, 4.0, brown)
		_cache["hormiga"] = ImageTexture.create_from_image(img)
	return _cache["hormiga"]


## Polilla: dos alas grises y cuerpo oscuro (pone huevos en la colmena).
static func polilla() -> Texture2D:
	if not _cache.has("polilla"):
		var size := 40
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var wing := Color(0.72, 0.68, 0.78)
		_paint_dot(img, 14.0, 20.0, 10.0, wing)
		_paint_dot(img, 26.0, 20.0, 10.0, wing)
		_paint_dot(img, 20.0, 20.0, 4.0, Color(0.4, 0.35, 0.42))
		_cache["polilla"] = ImageTexture.create_from_image(img)
	return _cache["polilla"]


## Huevo de polilla: óvalo crema que late hasta eclosionar.
static func egg() -> Texture2D:
	if not _cache.has("egg"):
		var size := 32
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		_paint_dot(img, 16.0, 16.0, 8.0, Color(0.95, 0.93, 0.82))
		_cache["egg"] = ImageTexture.create_from_image(img)
	return _cache["egg"]


static func tower() -> Texture2D:
	if not _cache.has("tower"):
		var pts := PackedVector2Array([
			Vector2(30, 16), Vector2(2, 2), Vector2(2, 30),
		])
		_cache["tower"] = _polygon(pts, Color(0.9, 0.55, 0.1), 32)
	return _cache["tower"]


## Pared normal: textura PNG de /textures (pared_base).
static func wall() -> Texture2D:
	if not _cache.has("wall"):
		_cache["wall"] = load("res://textures/pared_base.png")
	return _cache["wall"]


## Pared reforzada: textura PNG de /textures (pared_reforzada).
static func reinforced_wall() -> Texture2D:
	if not _cache.has("reinforced_wall"):
		_cache["reinforced_wall"] = load("res://textures/pared_reforzada.png")
	return _cache["reinforced_wall"]


## Pared trampa: estrella de pinchos (como los de Bloons). Se consume al tocarla.
static func trap() -> Texture2D:
	if not _cache.has("trap"):
		_cache["trap"] = _star_texture(8, 30.0, 14.0, Color(0.35, 0.33, 0.42), 64)
	return _cache["trap"]


## Torre doble: dos aguijones apuntando al mismo lado.
static func double_tower() -> Texture2D:
	if not _cache.has("double_tower"):
		var polys: Array = [
			PackedVector2Array([Vector2(30, 10), Vector2(2, 2), Vector2(2, 18)]),
			PackedVector2Array([Vector2(30, 22), Vector2(2, 14), Vector2(2, 30)]),
		]
		_cache["double_tower"] = _polygons(polys, Color(0.9, 0.5, 0.1), 32)
	return _cache["double_tower"]



## Guardia: abeja gorda naranja, cuerpo a cuerpo.
static func guardia() -> Texture2D:
	if not _cache.has("guardia"):
		_cache["guardia"] = _bee_texture_colored(48, 14.0, Color(0.95, 0.62, 0.12), Color(0.3, 0.18, 0.05))
	return _cache["guardia"]


## Largo alcance: abeja celeste y fina, dispara aguijones.
static func long_range() -> Texture2D:
	if not _cache.has("long_range"):
		_cache["long_range"] = _bee_texture_colored(40, 10.0, Color(0.55, 0.8, 1.0), Color(0.1, 0.22, 0.35))
	return _cache["long_range"]



## Edificio base: hexágono dorado con puerta oscura (colmena/ciudadela).
static func building() -> Texture2D:
	if not _cache.has("building"):
		_cache["building"] = _building_texture(Color(0.25, 0.16, 0.05))
	return _cache["building"]


## Guardería: colmena dorada con puerta verde.
static func guarderia() -> Texture2D:
	if not _cache.has("guarderia"):
		_cache["guarderia"] = _building_texture(Color(0.2, 0.6, 0.3))
	return _cache["guarderia"]


## Cultivadora: colmena dorada con puerta violeta.
static func cultivadora() -> Texture2D:
	if not _cache.has("cultivadora"):
		_cache["cultivadora"] = _building_texture(Color(0.55, 0.35, 0.8))
	return _cache["cultivadora"]


## Generador interno: hexágono dorado con una puerta del color indicado.
static func _building_texture(door_color: Color) -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size / 2.0, size / 2.0)
	var golden := Color(1.0, 0.78, 0.25)
	# Hexágono exterior (cuerpo del edificio).
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i - 30.0)
		pts.append(c + Vector2(cos(a), sin(a)) * 56.0)
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				img.set_pixel(x, y, golden)
	# Puerta (rectángulo al pie, del color del subtipo).
	for y in size:
		for x in size:
			if absf(x - c.x) <= 16.0 and y >= c.y + 8.0 and y <= c.y + 50.0:
				img.set_pixel(x, y, door_color)
	return ImageTexture.create_from_image(img)

# --- Generadores internos (no cachean; los públicos sí) ---

static func _circle(radius: int, color: Color, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size / 2.0, size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= radius:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


## Pinta un círculo relleno sobre `img` (para componer sprites de varios colores).
static func _paint_dot(img: Image, cx: float, cy: float, r: float, color: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy)) <= r:
				img.set_pixel(x, y, color)


static func _polygon(points: PackedVector2Array, color: Color, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


## Varios polígonos del mismo color (ej. los dos aguijones de la torre doble).
static func _polygons(polys: Array, color: Color, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			for poly in polys:
				if Geometry2D.is_point_in_polygon(p, poly):
					img.set_pixel(x, y, color)
					break
	return ImageTexture.create_from_image(img)


## Estrella de `spikes` puntas (pinchos de la trampa): alterna radio exterior/interior.
static func _star_texture(spikes: int, outer: float, inner: float, color: Color, size: int) -> ImageTexture:
	var pts := PackedVector2Array()
	var center := Vector2(size / 2.0, size / 2.0)
	for i in spikes * 2:
		var a: float = deg_to_rad(90.0 + float(i) * 180.0 / spikes)
		var r: float = outer if i % 2 == 0 else inner
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return _polygon(pts, color, size)


## Abeja: círculo amarillo con rayas oscuras (visto desde arriba). `radius` escala el cuerpo.
static func _bee_texture(size: int, radius: float) -> ImageTexture:
	return _bee_texture_colored(size, radius, Color(1.0, 0.85, 0.2), Color(0.25, 0.18, 0.05))


## Variante coloreada de la abeja (los aliados usan su propio color).
static func _bee_texture_colored(size: int, radius: float, body: Color, stripe: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size / 2.0, size / 2.0)
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= radius:
				img.set_pixel(x, y, body)
	# Rayas oscuras (proporcionales al radio del cuerpo).
	var stripe_half: float = radius * 0.2
	var stripe_gap: float = radius * 0.45
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= radius:
				var dx := p.x - c.x
				if absf(dx) < stripe_half or absf(dx - stripe_gap) < stripe_half or absf(dx + stripe_gap) < stripe_half:
					img.set_pixel(x, y, stripe)
	return ImageTexture.create_from_image(img)
