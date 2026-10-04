extends Node

## Autoload "Game": estado global compartido (materiales y definiciones de construcción).

signal materials_changed(value: int)
## Se emite cuando cambia la cantidad de abejas colocadas o la capacidad.
signal slots_changed(used: int, capacity: int)
## Se emite cuando cambia la cantidad de torres gratis disponibles.
signal free_towers_changed(count: int)

## Tipos de estructura que se pueden construir.
enum BuildType { WALL, REINFORCED, TRAP, TOWER, DOUBLE_TOWER, BASE, GUARDERIA, CULTIVADORA, GUARDIA, LONG_RANGE }

## Definiciones de lo construible: nombre y costo.
## El orden de las claves es el orden en que aparecen las tarjetas del menú.
const BUILD_DEFS := {
	BuildType.WALL: { "name": "Pared", "cost": 5 },
	BuildType.REINFORCED: { "name": "Pared reforzada", "cost": 15 },
	BuildType.TRAP: { "name": "Pared trampa", "cost": 6 },
	BuildType.TOWER: { "name": "Torre", "cost": 30 },
	BuildType.DOUBLE_TOWER: { "name": "Torre doble", "cost": 90 },
	BuildType.BASE: { "name": "Base", "cost": 70 },
	BuildType.GUARDERIA: { "name": "Guardería", "cost": 100 },
	BuildType.CULTIVADORA: { "name": "Cultivadora", "cost": 140 },
	BuildType.GUARDIA: { "name": "Guardia", "cost": 40 },
	BuildType.LONG_RANGE: { "name": "Largo alcance", "cost": 50 },
}

## Material de construcción disponible (lo ganamos al destruir enemigos).
## 500 = 1 base (80) + 1 guarderia (150) + 3 torres (160). Arrancamos con un edificio y tres torres.
var materials: int = 500

## Torres comunes gratis acumuladas (las entrega la guardería al terminar
## cada oleada). Se consumen al colocar una torre sin pagar miel.
var free_towers: int = 0
## Nivel de cada torre gratis en cola (el frente es la próxima a consumirse).
var _free_tower_levels: Array[int] = []

## Sistema de slots de abejas: cuántas "abejas-torre" podemos colocar.
## Al inicio solo se puede crear una; los edificios amplían esta capacidad.
## (Las paredes y trampas NO consumen slots: son libres.)

## Cuántos slots de abeja consume cada tipo (las torres y aliados, 1 cada uno).
## Las paredes y trampas NO consumen: no están acá.
const SLOT_COST := {
	BuildType.TOWER: 1,
	BuildType.DOUBLE_TOWER: 1,
	BuildType.GUARDIA: 1,
	BuildType.LONG_RANGE: 1,
}

## Capacidad máxima de abejas colocables. Arranca en 1.
var slot_capacity: int = 1
## Abejas colocadas en orden (primera en entrar, última en salir). Guarda los nodos.
var _slotted: Array[Node] = []
## Cuántos slots consume cada abeja colocada (las torres y aliados valen 1).
var _slot_costs: Dictionary = {}

## Costo de mejora para pasar de un nivel al siguiente (nivel 1→2 = 100, 2→3 = 200).
const UPGRADE_COST := {
	1: 100,
	2: 200,
}

## Tipos que se pueden mejorar (3 niveles). Las paredes, trampas y la torre
## doble solo se venden, no se mejoran.
const UPGRADABLE := {
	BuildType.BASE: true,
	BuildType.GUARDERIA: true,
	BuildType.CULTIVADORA: true,
	BuildType.TOWER: true,
	BuildType.GUARDIA: true,
	BuildType.LONG_RANGE: true,
}

## Stats por nivel de cada tipo mejorable (nivel 1 = valor base).
## Los multiplicadores (`*_mult`) se aplican sobre los stats base del nodo; los
## valores absolutos (`slots`, `honey`, `towers`, `tower_level`) se usan directo.
const LEVEL_STATS := {
	BuildType.BASE: [
		{ "slots": 4 },
		{ "slots": 7 },
		{ "slots": 13 },
	],
	BuildType.GUARDERIA: [
		{ "towers": 1, "tower_level": 1 },
		{ "towers": 1, "tower_level": 2 },
		{ "towers": 2, "tower_level": 3 },
	],
	BuildType.CULTIVADORA: [
		{ "honey": 100 },
		{ "honey": 200 },
		{ "honey": 350 },
	],
	BuildType.TOWER: [
		{ "fire_mult": 1.0 },
		{ "fire_mult": 0.7 },
		{ "fire_mult": 0.5 },
	],
	BuildType.LONG_RANGE: [
		{ "damage_mult": 1.0, "fire_mult": 1.0 },
		{ "damage_mult": 3.0, "fire_mult": 1.0 },
		{ "damage_mult": 5.0, "fire_mult": 0.75 },
	],
	BuildType.GUARDIA: [
		{ "damage_mult": 1.0, "health_mult": 1.0 },
		{ "damage_mult": 1.5, "health_mult": 1.5 },
		{ "damage_mult": 2.0, "health_mult": 2.0 },
	],
}


## ¿El `type` de construcción consume slots de abeja?
static func consumes_slot(type: int) -> bool:
	return type in SLOT_COST


## Cuántos slots consume el `type` (0 para paredes/trampas/edificios).
static func slot_cost(type: int) -> int:
	return SLOT_COST.get(type, 0)


## Slots ocupados en total (suma el costo de cada abeja colocada).
func _slots_used() -> int:
	var total := 0
	for cost in _slot_costs.values():
		total += cost
	return total


## ¿Queda al menos un slot libre?
func has_slot() -> bool:
	return has_slots(1)


## ¿Entran `count` slots libres?
func has_slots(count: int) -> bool:
	return _slots_used() + count <= slot_capacity


## Cantidad de slots ocupados.
func slots_used() -> int:
	return _slots_used()


## Registra una abeja recién colocada (con su costo en slots). Devuelve false si no entra.
func register_slotted(node: Node, cost: int = 1) -> bool:
	if _slots_used() + cost > slot_capacity:
		return false
	_slotted.append(node)
	_slot_costs[node] = cost
	slots_changed.emit(_slots_used(), slot_capacity)
	return true


## Saca una abeja de la lista (cuando se destruye).
func unregister_slotted(node: Node) -> void:
	if _slotted.has(node):
		_slotted.erase(node)
		_slot_costs.erase(node)
		slots_changed.emit(_slots_used(), slot_capacity)


## Amplía la capacidad en `amount` slots (los edificios suman 3).
func increase_capacity(amount: int) -> void:
	slot_capacity += amount
	slots_changed.emit(_slots_used(), slot_capacity)


## Reduce la capacidad en `amount` y elimina las últimas abejas hasta entrar (LIFO).
func decrease_capacity(amount: int) -> Array[Node]:
	slot_capacity = maxi(0, slot_capacity - amount)
	return _trim_to_capacity()


## Destruye (saca de la lista) las abejas que excedan la capacidad, de atrás
## hacia adelante. Devuelve las que quedaron fuera.
func _trim_to_capacity() -> Array[Node]:
	var removed: Array[Node] = []
	while _slots_used() > slot_capacity and not _slotted.is_empty():
		var node: Node = _slotted.pop_back()
		_slot_costs.erase(node)
		removed.append(node)
	slots_changed.emit(_slots_used(), slot_capacity)
	return removed


func can_afford(cost: int) -> bool:
	return materials >= cost


func spend(cost: int) -> void:
	materials -= cost
	materials_changed.emit(materials)


func gain(amount: int) -> void:
	materials += amount
	materials_changed.emit(materials)


## ¿Queda al menos una torre gratis por colocar?
func has_free_tower() -> bool:
	return free_towers > 0


## Entrega una torre gratis de `level` (la guardería la otorga al final de cada
## oleada; a más nivel de guardería, torres de más nivel).
func grant_free_tower(level: int = 1) -> void:
	free_towers += 1
	_free_tower_levels.append(level)
	free_towers_changed.emit(free_towers)


## Consume una torre gratis al colocarla y devuelve su nivel (1 por defecto).
func consume_free_tower() -> int:
	free_towers = maxi(0, free_towers - 1)
	var lvl := 1
	if not _free_tower_levels.is_empty():
		lvl = _free_tower_levels.pop_front()
	free_towers_changed.emit(free_towers)
	return lvl


## ¿El `type` se puede mejorar (tiene 3 niveles)?
static func is_upgradable(type: int) -> bool:
	return type in UPGRADABLE


## Nivel máximo de un tipo (3 si es mejorable, 1 si no).
static func max_level(type: int) -> int:
	return 3 if is_upgradable(type) else 1


## Costo para pasar de `level` a `level + 1` (0 si ya está al máximo).
static func upgrade_cost(type: int, level: int) -> int:
	if level >= max_level(type):
		return 0
	return UPGRADE_COST[level]


## Lee un stat del nivel `level` de `type`. Devuelve `fallback` si no existe.
static func level_stat(type: int, level: int, key: String, fallback):
	if not LEVEL_STATS.has(type):
		return fallback
	var levels: Array = LEVEL_STATS[type]
	var idx: int = clampi(level, 1, levels.size()) - 1
	return levels[idx].get(key, fallback)


## Total invertido en una construcción de `type` a nivel `level` (compra + mejoras).
static func total_invested(type: int, level: int) -> int:
	var total: int = BUILD_DEFS[type]["cost"]
	for l in range(1, level):
		total += UPGRADE_COST[l]
	return total


## Miel que devuelve vender una construcción: 3/8 de lo invertido en total.
static func sell_value(type: int, level: int) -> int:
	return int(round(float(total_invested(type, level)) * 3.0 / 8.0))


## Restaura el estado global al de una partida nueva. Se llama antes de
## recargar la escena o de volver al menú, porque `Game` (autoload) no se
## reinicia al recargar la escena.
func reset() -> void:
	materials = 500
	free_towers = 0
	_free_tower_levels.clear()
	slot_capacity = 1
	_slotted.clear()
	_slot_costs.clear()


func _ready() -> void:
	# Precargamos todas las texturas para evitar cortes de FPS al jugar.
	Art.preload_all()
