class_name PauseMenu
extends CanvasLayer

## Menú de pausa: se abre con Esc, congela el árbol y ofrece Continuar,
## Reiniciar y Volver al menú. Su nodo raíz tiene process_mode = When Paused
## para seguir recibiendo input con el juego pausado.


func _ready() -> void:
	visible = false
	$Center/Card/VBox/ContinuarButton.pressed.connect(_on_continuar_pressed)
	$Center/Card/VBox/ReiniciarButton.pressed.connect(_on_reiniciar_pressed)
	$Center/Card/VBox/MenuButton.pressed.connect(_on_menu_pressed)


## Esc con el juego pausado (y el menú abierto) reanuda la partida.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if get_tree().paused and visible:
			close()
			get_viewport().set_input_as_handled()


## Pausa el árbol y muestra el menú.
func open() -> void:
	visible = true
	get_tree().paused = true


## Despausa y oculta el menú.
func close() -> void:
	visible = false
	get_tree().paused = false


func _on_continuar_pressed() -> void:
	close()


func _on_reiniciar_pressed() -> void:
	Game.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	Game.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
