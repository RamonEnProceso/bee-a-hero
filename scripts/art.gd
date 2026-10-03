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
	big_tower()
	guardia()
	long_range()
	piranas()
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
		Game.BuildType.BIG_TOWER:
			return big_tower()
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
		Game.BuildType.PIRANAS:
			return piranas()
	return wall()


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


static func tower() -> Texture2D:
	if not _cache.has("tower"):
		var pts := PackedVector2Array([
			Vector2(30, 16), Vector2(2, 2), Vector2(2, 30),
		])
		_cache["tower"] = _polygon(pts, Color(0.9, 0.55, 0.1), 32)
	return _cache["tower"]


## Pared normal: hexágono marrón que rellena la celda.
static func wall() -> Texture2D:
	if not _cache.has("wall"):
		_cache["wall"] = _wall_texture(Color(0.55, 0.35, 0.15))
	return _cache["wall"]


## Pared reforzada: gris acero (más vida, contra avispones).
static func reinforced_wall() -> Texture2D:
	if not _cache.has("reinforced_wall"):
		_cache["reinforced_wall"] = _wall_texture(Color(0.42, 0.44, 0.52))
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


## Cañón: cuerpo oscuro + cañón de acero (ocupa 2x2 hexágonos).
static func big_tower() -> Texture2D:
	if not _cache.has("big_tower"):
		var size := 128
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var body_c := Vector2(48, 64)
		var body_color := Color(0.25, 0.24, 0.28)
		var barrel_color := Color(0.5, 0.52, 0.6)
		for y in size:
			for x in size:
				var p := Vector2(x + 0.5, y + 0.5)
				if p.distance_to(body_c) <= 34.0:
					img.set_pixel(x, y, body_color)
				if p.x >= 64.0 and p.x <= 122.0 and absf(p.y - 64.0) <= 12.0:
					img.set_pixel(x, y, barrel_color)
		_cache["big_tower"] = ImageTexture.create_from_image(img)
	return _cache["big_tower"]


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


## Pirañas: enjambre chico rojo (ocupa 4 slots, corto alcance).
static func piranas() -> Texture2D:
	if not _cache.has("piranas"):
		_cache["piranas"] = _bee_texture_colored(36, 8.0, Color(0.9, 0.25, 0.2), Color(0.35, 0.1, 0.08))
	return _cache["piranas"]


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


## Hexágono pointy-top que rellena la celda (los subtipos de pared usan su color).
static func _wall_texture(color: Color) -> ImageTexture:
	var size := 64
	var pts := PackedVector2Array()
	var center := Vector2(size / 2.0, size / 2.0)
	for i in 6:
		var a: float = deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(a), sin(a)) * 30.0)
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
