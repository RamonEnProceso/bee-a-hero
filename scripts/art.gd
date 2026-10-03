class_name Art
extends RefCounted

## Genera texturas placeholder para las entidades (sprites editables luego).
## Para poner arte real: reemplazar estos generadores o asignar un PNG al Sprite2D
## de cada escena (Sprite2D.texture = load("res://assets/...")).

static var _cache: Dictionary = {}


static func _remember(key: String, tex: ImageTexture) -> ImageTexture:
	if not _cache.has(key):
		_cache[key] = tex
	return _cache[key]


## Textura de un círculo relleno.
static func _circle(radius: int, color: Color, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size / 2.0, size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= radius:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


## Textura de un polígono relleno (puntos en coordenadas de la textura).
static func _polygon(points: PackedVector2Array, color: Color, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


static func queen() -> Texture2D:
	return _remember("queen", _circle(24, Color(1.0, 0.84, 0.25), 64))


static func projectile() -> Texture2D:
	return _remember("projectile", _circle(4, Color(1.0, 0.9, 0.3), 16))


static func bee() -> Texture2D:
	return _remember("bee", _bee_texture())


## Abeja: círculo amarillo con rayas oscuras (visto desde arriba).
static func _bee_texture() -> ImageTexture:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(16.0, 16.0)
	var radius := 10.0
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= radius:
				img.set_pixel(x, y, Color(1.0, 0.85, 0.2))
	# Rayas oscuras.
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= radius:
				var dx := p.x - c.x
				if absf(dx) < 2.0 or absf(dx - 4.5) < 2.0 or absf(dx + 4.5) < 2.0:
					img.set_pixel(x, y, Color(0.25, 0.18, 0.05))
	return ImageTexture.create_from_image(img)


static func enemy() -> Texture2D:
	var pts := PackedVector2Array([
		Vector2(30, 16), Vector2(4, 4), Vector2(4, 28),
	])
	return _remember("enemy", _polygon(pts, Color(0.85, 0.15, 0.15), 32))


static func tower() -> Texture2D:
	var pts := PackedVector2Array([
		Vector2(30, 16), Vector2(2, 2), Vector2(2, 30),
	])
	return _remember("tower", _polygon(pts, Color(0.9, 0.55, 0.1), 32))


## Hexágono pointy-top que rellena la celda (hex_size=32).
static func wall() -> Texture2D:
	var size := 64
	var pts := PackedVector2Array()
	var center := Vector2(size / 2.0, size / 2.0)
	for i in 6:
		var a: float = deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(a), sin(a)) * 30.0)
	return _remember("wall", _polygon(pts, Color(0.55, 0.35, 0.15), size))
