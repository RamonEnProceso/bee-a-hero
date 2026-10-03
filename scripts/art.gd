class_name Art
extends RefCounted

## Genera texturas placeholder para las entidades (sprites editables luego).
## Todas se cachean para generarse UNA sola vez. `preload()` las crea todas al inicio
## para evitar cortes de FPS en medio del juego.
## Para poner arte real: reemplazar estos generadores o asignar un PNG al Sprite2D.

static var _cache: Dictionary = {}


## Genera (una sola vez) todas las texturas. Se llama al arrancar el juego.
static func preload_all() -> void:
	queen()
	bee()
	suicide_bee()
	enemy()
	tower()
	wall()
	projectile()
	pickup()


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


static func tower() -> Texture2D:
	if not _cache.has("tower"):
		var pts := PackedVector2Array([
			Vector2(30, 16), Vector2(2, 2), Vector2(2, 30),
		])
		_cache["tower"] = _polygon(pts, Color(0.9, 0.55, 0.1), 32)
	return _cache["tower"]


## Hexágono pointy-top que rellena la celda (hex_size=32).
static func wall() -> Texture2D:
	if not _cache.has("wall"):
		var size := 64
		var pts := PackedVector2Array()
		var center := Vector2(size / 2.0, size / 2.0)
		for i in 6:
			var a: float = deg_to_rad(60.0 * i - 30.0)
			pts.append(center + Vector2(cos(a), sin(a)) * 30.0)
		_cache["wall"] = _polygon(pts, Color(0.55, 0.35, 0.15), size)
	return _cache["wall"]


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
