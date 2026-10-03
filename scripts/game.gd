extends Node

## Autoload "Game": estado global compartido (materiales y definiciones de construcción).

signal materials_changed(value: int)
## Se emite cuando cambia la cantidad de abejas colocadas o la capacidad.
signal slots_changed(used: int, capacity: int)

## Tipos de estructura que se pueden construir.
enum BuildType { WALL, REINFORCED, TRAP, TOWER, DOUBLE_TOWER, BIG_TOWER, BASE }

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
}

## Material de construcción disponible (lo ganamos al destruir enemigos).
## 130 = 3 torres (120) + algo de defensa. La mecánica principal son las
## paredes y trampas baratas; las torres (y el cañón) son el golpe caro.
var materials: int = 130

## Sistema de slots de abejas: cuántas "abejas-torre" podemos colocar.
## Al inicio solo se puede crear una; los edificios amplían esta capacidad.
## (Las paredes y trampas NO consumen slots: son libres.)

## Tipos que ocupan un slot de abeja (las torres; más adelante los aliados).
const SLOTTED_TYPES := [BuildType.TOWER, BuildType.DOUBLE_TOWER, BuildType.BIG_TOWER]

## Capacidad máxima de abejas colocables. Arranca en 1.
var slot_capacity: int = 1
## Abejas colocadas en orden (primera en entrar, última en salir). Guarda los nodos.
var _slotted: Array[Node] = []


## ¿El `type` de construcción consume un slot de abeja?
static func consumes_slot(type: int) -> bool:
	return type in SLOTTED_TYPES


## ¿Queda un slot libre para colocar una abeja?
func has_slot() -> bool:
	return _slotted.size() < slot_capacity


## Cantidad de slots ocupados.
func slots_used() -> int:
	return _slotted.size()


## Registra una abeja recién colocada. Devuelve false si no hay slot libre.
func register_slotted(node: Node) -> bool:
	if _slotted.size() >= slot_capacity:
		return false
	_slotted.append(node)
	slots_changed.emit(_slotted.size(), slot_capacity)
	return true


## Saca una abeja de la lista (cuando se destruye).
func unregister_slotted(node: Node) -> void:
	if _slotted.has(node):
		_slotted.erase(node)
		slots_changed.emit(_slotted.size(), slot_capacity)


## Amplía la capacidad en `amount` slots (los edificios suman 3).
func increase_capacity(amount: int) -> void:
	slot_capacity += amount
	slots_changed.emit(_slotted.size(), slot_capacity)


## Reduce la capacidad en `amount` y elimina las últimas abejas hasta entrar (LIFO).
func decrease_capacity(amount: int) -> Array[Node]:
	slot_capacity = maxi(0, slot_capacity - amount)
	return _trim_to_capacity()


## Destruye (saca de la lista) las abejas que excedan la capacidad, de atrás
## hacia adelante. Devuelve las que quedaron fuera.
func _trim_to_capacity() -> Array[Node]:
	var removed: Array[Node] = []
	while _slotted.size() > slot_capacity:
		removed.append(_slotted.pop_back())
	slots_changed.emit(_slotted.size(), slot_capacity)
	return removed


func can_afford(cost: int) -> bool:
	return materials >= cost


func spend(cost: int) -> void:
	materials -= cost
	materials_changed.emit(materials)


func gain(amount: int) -> void:
	materials += amount
	materials_changed.emit(materials)


func _ready() -> void:
	# Precargamos todas las texturas para evitar cortes de FPS al jugar.
	Art.preload_all()
