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
	bird()
	cat_paw()
	bear_paw()
	tower()
	wall()
	reinforced_wall()
	spiky_wall()
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
		Game.BuildType.SPIKY:
			return spiky_wall()
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


## Pájaro ENORME: solo "entra" su cabeza (pico largo + cabeza), picotea y se va.
## Ocupa ~128 px ≈ 2 hexágonos de largo.
static func bird() -> Texture2D:
	if not _cache.has("bird"):
		_cache["bird"] = _bird_texture()
	return _cache["bird"]


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


## Pared de púas: rojiza (devuelve daño al que la golpea).
static func spiky_wall() -> Texture2D:
	if not _cache.has("spiky_wall"):
		_cache["spiky_wall"] = _wall_texture(Color(0.6, 0.26, 0.32))
	return _cache["spiky_wall"]


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
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size / 2.0, size / 2.0)
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= radius:
				img.set_pixel(x, y, Color(1.0, 0.85, 0.2))
	# Rayas oscuras (proporcionales al radio del cuerpo).
	var stripe_half: float = radius * 0.2
	var stripe_gap: float = radius * 0.45
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= radius:
				var dx := p.x - c.x
				if absf(dx) < stripe_half or absf(dx - stripe_gap) < stripe_half or absf(dx + stripe_gap) < stripe_half:
					img.set_pixel(x, y, Color(0.25, 0.18, 0.05))
	return ImageTexture.create_from_image(img)


## Cabeza de pájaro gigante: cabeza celeste + pico largo naranja + ojo.
## Apunta hacia +X (el sprite rota para mirar al objetivo, como el resto).
static func _bird_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var head_color := Color(0.55, 0.7, 0.95)
	var beak_color := Color(0.95, 0.62, 0.15)
	var eye_color := Color(0.1, 0.1, 0.15)
	var head_c := Vector2(44, 64)
	# Pico: triángulo que sobresale hacia +X.
	var beak := PackedVector2Array([Vector2(126, 64), Vector2(48, 40), Vector2(48, 88)])

	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(head_c) <= 42.0:
				img.set_pixel(x, y, head_color)
			if p.distance_to(Vector2(56, 48)) <= 8.0:
				img.set_pixel(x, y, eye_color)
			if Geometry2D.is_point_in_polygon(p, beak):
				img.set_pixel(x, y, beak_color)

	return ImageTexture.create_from_image(img)
