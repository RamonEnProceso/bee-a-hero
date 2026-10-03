extends Node

## Autoload "Game": estado global compartido (materiales y definiciones de construcción).

signal materials_changed(value: int)

## Tipos de estructura que se pueden construir.
enum BuildType { WALL, REINFORCED, TRAP, TOWER, DOUBLE_TOWER, BIG_TOWER }

## Definiciones de lo construible: nombre y costo.
## El orden de las claves es el orden en que aparecen las tarjetas del menú.
const BUILD_DEFS := {
	BuildType.WALL: { "name": "Pared", "cost": 5 },
	BuildType.REINFORCED: { "name": "Pared reforzada", "cost": 15 },
	BuildType.TRAP: { "name": "Pared trampa", "cost": 6 },
	BuildType.TOWER: { "name": "Torre", "cost": 50 },
	BuildType.DOUBLE_TOWER: { "name": "Torre doble", "cost": 90 },
	BuildType.BIG_TOWER: { "name": "Cañón", "cost": 200 },
}

## Material de construcción disponible (lo ganamos al destruir enemigos).
## 130 = 2 torres (100) + algo de defensa. La mecánica principal son las
## paredes y trampas baratas; las torres (y el cañón) son el golpe caro.
var materials: int = 130


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
