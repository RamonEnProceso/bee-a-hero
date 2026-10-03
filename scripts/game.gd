extends Node

## Autoload "Game": estado global compartido (materiales y definiciones de construcción).

signal materials_changed(value: int)

## Tipos de estructura que se pueden construir.
enum BuildType { WALL, TOWER }

## Definiciones de lo construible: nombre, costo y dibujo placeholder.
## El orden de las claves es el orden en que aparecen las tarjetas del menú.
const BUILD_DEFS := {
	BuildType.WALL: {
		"name": "Pared",
		"cost": 5,
		"shape": "hex",
		"color": Color(0.55, 0.35, 0.15),
	},
	BuildType.TOWER: {
		"name": "Torre",
		"cost": 40,
		"shape": "tri",
		"color": Color(0.9, 0.55, 0.1),
	},
}

## Material de construcción disponible (lo ganamos al destruir enemigos).
## 130 = colchón inicial: alcanza para 3 torres (120) + 2 paredes (10).
var materials: int = 130


func can_afford(cost: int) -> bool:
	return materials >= cost


func spend(cost: int) -> void:
	materials -= cost
	materials_changed.emit(materials)


func gain(amount: int) -> void:
	materials += amount
	materials_changed.emit(materials)
