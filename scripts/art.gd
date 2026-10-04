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
	enemy_projectile()
	tower()
	wall()
	reinforced_wall()
	trap()
	double_tower()
	guardia()
	long_range()
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
	# Disparo de las abejas: textura PNG de /textures (Miel_proyectil).
	if not _cache.has("projectile"):
		_cache["projectile"] = load("res://textures/Miel_proyectil.png")
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




## Aguijón que dispara la avispa tiradora (pequeño, color naranja).
static func enemy_projectile() -> Texture2D:
	if not _cache.has("enemy_projectile"):
		_cache["enemy_projectile"] = _circle(3, Color(1.0, 0.45, 0.1), 16)
	return _cache["enemy_projectile"]


static func tower() -> Texture2D:
	# Torre normal: precarga sus 6 frames (3 niveles x 2 aleteos) y devuelve el icono.
	for lvl in range(1, 4):
		for fr in range(2):
			tower_frame(lvl, fr)
	return tower_frame(1, 0)


## Frame de aleteo de la torre normal (AbejaBase) para `level` (1-3) y `frame` (0-1).
static func tower_frame(level: int, frame: int) -> Texture2D:
	return _bee_frame("tower", "AbejaBase", level, frame)


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


## Pared trampa: textura PNG de /textures (pared_trampa).
static func trap() -> Texture2D:
	if not _cache.has("trap"):
		_cache["trap"] = load("res://textures/pared_trampa.png")
	return _cache["trap"]


## Torre doble: dos aguijones apuntando al mismo lado.
static func double_tower() -> Texture2D:
	# Precarga sus 6 frames (3 niveles x 2 aleteos) y devuelve el icono (nivel 1, frame 0).
	for lvl in range(1, 4):
		for fr in range(2):
			double_tower_frame(lvl, fr)
	return double_tower_frame(1, 0)


## Frame de aleteo de la torre doble (AbejaDoble) para `level` (1-3) y `frame` (0-1).
static func double_tower_frame(level: int, frame: int) -> Texture2D:
	return _bee_frame("double_tower", "AbejaDoble", level, frame)



## Patovica (guardia): abeja gorda cuerpo a cuerpo. Devuelve el frame 0 del nivel 1
## (es el icono del menú) y precarga los 6 frames (3 niveles x 2 frames de aleteo).
static func guardia() -> Texture2D:
	for lvl in range(1, 4):
		for fr in range(2):
			guardia_frame(lvl, fr)
	return guardia_frame(1, 0)


## Frame de aleteo de la Patovica (AbejaPatovica) para `level` (1-3) y `frame` (0-1).
static func guardia_frame(level: int, frame: int) -> Texture2D:
	return _bee_frame("guardia", "AbejaPatovica", level, frame)


## Frame de aleteo genérico para las abejas con dos PNGs por nivel:
## carga res://textures/<nombre>_<level>_0<frame>.png y lo cachea.
static func _bee_frame(key: String, path_name: String, level: int, frame: int) -> Texture2D:
	var k := "%s_%d_%d" % [key, level, frame]
	if not _cache.has(k):
		_cache[k] = load("res://textures/%s_%d_%02d.png" % [path_name, level, frame])
	return _cache[k]


## Largo alcance: abeja celeste y fina, dispara aguijones.
static func long_range() -> Texture2D:
	# Precarga sus 6 frames (3 niveles x 2 aleteos) y devuelve el icono (nivel 1, frame 0).
	for lvl in range(1, 4):
		for fr in range(2):
			long_range_frame(lvl, fr)
	return long_range_frame(1, 0)


## Frame de aleteo del largo alcance (AbejaLargaDistancia) para `level` (1-3) y `frame` (0-1).
static func long_range_frame(level: int, frame: int) -> Texture2D:
	return _bee_frame("long_range", "AbejaLargaDistancia", level, frame)



## Edificio base (nivel 1): textura PNG de /textures.
static func building() -> Texture2D:
	return building_leveled(1)


## Textura del edificio base según su nivel de mejora: 1 = Base, 2 = Base_01, 3 = Base_02.
static func building_leveled(level: int) -> Texture2D:
	var key := "building_%d" % level
	if not _cache.has(key):
		var path := "res://textures/Base.png"
		if level >= 3:
			path = "res://textures/Base_02.png"
		elif level == 2:
			path = "res://textures/Base_01.png"
		_cache[key] = load(path)
	return _cache[key]


## Guardería (nivel 1): textura PNG de /textures.
static func guarderia() -> Texture2D:
	return guarderia_leveled(1)


## Textura de la guardería según su nivel de mejora: 1 = Guarderia_00, 2 = Guarderia_01, 3 = Guarderia_02.
static func guarderia_leveled(level: int) -> Texture2D:
	var key := "guarderia_%d" % level
	if not _cache.has(key):
		_cache[key] = load("res://textures/Guarderia_%02d.png" % (level - 1))
	return _cache[key]


## Cultivadora (nivel 1): textura PNG de /textures.
static func cultivadora() -> Texture2D:
	return cultivadora_leveled(1)


## Textura de la cultivadora según su nivel de mejora: 1 = Cultivadora_00, 2 = Cultivadora_01, 3 = Cultivadora_02.
static func cultivadora_leveled(level: int) -> Texture2D:
	var key := "cultivadora_%d" % level
	if not _cache.has(key):
		_cache[key] = load("res://textures/Cultivadora_%02d.png" % (level - 1))
	return _cache[key]


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
