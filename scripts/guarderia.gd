class_name Guarderia
extends Building

## Guardería: tarda 1 ronda en construirse y, al terminar cada oleada,
## entrega una torre común GRATIS para colocar (el jugador la pone con 0 miel).
## No suma slots de abeja: su ganancia es la torre gratis.


## Textura propia (puerta verde).
func _texture() -> Texture2D:
	return Art.guarderia()


## Entrega una torre gratis al final de cada oleada (el jugador la coloca después).
func _reward() -> void:
	Game.grant_free_tower()
