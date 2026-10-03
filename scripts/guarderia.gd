class_name Guarderia
extends Building

## Guardería: tarda 1 ronda en construirse y, al terminar cada oleada,
## entrega una torre común GRATIS para colocar (el jugador la pone con 0 miel).
## No suma slots de abeja: su ganancia es la torre gratis.


## Textura propia (puerta verde).
func _texture() -> Texture2D:
	return Art.guarderia()


## Entrega torres gratis al final de cada oleada según su nivel: 1 torre normal,
## luego 1 de nivel 2, luego 2 de nivel 3.
func _reward() -> void:
	var towers: int = Game.level_stat(build_type, level, "towers", 1)
	var tower_level: int = Game.level_stat(build_type, level, "tower_level", 1)
	for i in towers:
		Game.grant_free_tower(tower_level)
