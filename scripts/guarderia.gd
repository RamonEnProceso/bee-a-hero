class_name Guarderia
extends Building

## Guardería: tarda 1 ronda en construirse y, al terminar cada oleada, regala una
## torre común en una celda libre vecina. Si no hay slot libre, el regalo se pierde.


## Textura propia (puerta verde).
func _texture() -> Texture2D:
	return Art.guarderia()


## Regala una torre común al final de cada oleada (si hay slot y celda libres).
func _reward() -> void:
	if not Game.has_slot():
		return
	var free_cell = _free_neighbor_cell()
	if free_cell == null:
		return
	var tower: Tower = grid.build_tower(free_cell)
	if tower != null:
		Game.register_slotted(tower)


## Celda libre vecina al edificio, o null si no hay ninguna.
func _free_neighbor_cell():
	for c in cells:
		for n in grid.get_neighbors(c):
			if grid.can_place(n):
				return n
	return null
