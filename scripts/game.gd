extends Node

## Autoload "Game": estado global compartido (materiales y definiciones de construcción).

signal materials_changed(value: int)
## Se emite cuando cambia la cantidad de abejas colocadas o la capacidad.
signal slots_changed(used: int, capacity: int)
## Se emite cuando cambia la cantidad de torres gratis disponibles.
signal free_towers_changed(count: int)

## Tipos de estructura que se pueden construir.
enum BuildType { WALL, REINFORCED, TRAP, TOWER, DOUBLE_TOWER, BIG_TOWER, BASE, GUARDERIA, CULTIVADORA, GUARDIA, LONG_RANGE, PIRANAS }

## Definiciones de lo construible: nombre y costo.
## El orden de las claves es el orden en que aparecen las tarjetas del menú.
const BUILD_DEFS := {
	BuildType.WALL: { "name": "Pared", "cost": 5 },
	BuildType.REINFORCED: { "name": "Pared reforzada", "cost": 15 },
	BuildType.TRAP: { "name": "Pared trampa", "cost": 6 },
	BuildType.TOWER: { "name": "Torre", "cost": 40 },
	BuildType.DOUBLE_TOWER: { "name": "Torre doble", "cost": 90 },
	BuildType.BIG_TOWER: { "name": "Cañón", "cost": 200 },
	BuildType.BASE: { "name": "Base", "cost": 80 },
	BuildType.GUARDERIA: { "name": "Guardería", "cost": 120 },
	BuildType.CULTIVADORA: { "name": "Cultivadora", "cost": 160 },
	BuildType.GUARDIA: { "name": "Guardia", "cost": 50 },
	BuildType.LONG_RANGE: { "name": "Largo alcance", "cost": 80 },
	BuildType.PIRANAS: { "name": "Pirañas", "cost": 70 },
}

## Material de construcción disponible (lo ganamos al destruir enemigos).
## 500 = 1 base (80) + 1 guarderia (150) + 3 torres (160). Arrancamos con un edificio y tres torres.
var materials: int = 500

## Torres comunes gratis acumuladas (las entrega la guardería al terminar
## cada oleada). Se consumen al colocar una torre sin pagar miel.
var free_towers: int = 0

## Sistema de slots de abejas: cuántas "abejas-torre" podemos colocar.
## Al inicio solo se puede crear una; los edificios amplían esta capacidad.
## (Las paredes y trampas NO consumen slots: son libres.)

## Cuántos slots de abeja consume cada tipo (las torres y aliados normales, 1;
## las pirañas ocupan 4). Las paredes y trampas NO consumen: no están acá.
const SLOT_COST := {
	BuildType.TOWER: 1,
	BuildType.DOUBLE_TOWER: 1,
	BuildType.BIG_TOWER: 1,
	BuildType.GUARDIA: 1,
	BuildType.LONG_RANGE: 1,
	BuildType.PIRANAS: 4,
}

## Capacidad máxima de abejas colocables. Arranca en 1.
var slot_capacity: int = 1
## Abejas colocadas en orden (primera en entrar, última en salir). Guarda los nodos.
var _slotted: Array[Node] = []
## Cuántos slots consume cada abeja colocada (la piraña vale 4).
var _slot_costs: Dictionary = {}


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


## Entrega una torre gratis (la guardería la otorga al final de cada oleada).
func grant_free_tower() -> void:
	free_towers += 1
	free_towers_changed.emit(free_towers)


## Consume una torre gratis al colocarla (no se descuenta miel).
func consume_free_tower() -> void:
	free_towers = maxi(0, free_towers - 1)
	free_towers_changed.emit(free_towers)


func _ready() -> void:
	# Precargamos todas las texturas para evitar cortes de FPS al jugar.
	Art.preload_all()
