extends Node

## Autoload "Game": estado global compartido (materiales y definiciones de construcción).

signal materials_changed(value: int)

## Tipos de estructura que se pueden construir.
enum BuildType { WALL, TOWER, REINFORCED, SPIKY }

## Definiciones de lo construible: nombre y costo.
## El orden de las claves es el orden en que aparecen las tarjetas del menú.
const BUILD_DEFS := {
	BuildType.WALL: { "name": "Pared", "cost": 5 },
	BuildType.TOWER: { "name": "Torre", "cost": 80 },
	BuildType.REINFORCED: { "name": "Pared reforzada", "cost": 15 },
	BuildType.SPIKY: { "name": "Pared de púas", "cost": 10 },
}

## Material de construcción disponible (lo ganamos al destruir enemigos).
## 130 = colchón inicial: alcanza para 1 torre (80) + 10 paredes (50).
## Las torres caras empujan a jugar a base de paredes, no de torretas.
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
