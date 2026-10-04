class_name MainMenu
extends Control

## Menú principal: título del juego, botón "Jugar" (arranca la partida) y
## botón "Cómo jugar" (muestra un panel con los controles).

@onready var how_to_panel: PanelContainer = $HowToPanel


func _ready() -> void:
	# Por si volvemos de una partida que quedó pausada, arrancamos despausados.
	get_tree().paused = false
	$Menu/VBox/JugarButton.pressed.connect(_on_jugar_pressed)
	$Menu/VBox/ComoJugarButton.pressed.connect(_on_como_jugar_pressed)
	$HowToPanel/Center/Card/VBox/CerrarButton.pressed.connect(_on_cerrar_pressed)


## Jugar: reinicia el estado global y carga la escena de la partida.
func _on_jugar_pressed() -> void:
	Game.reset()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


## Muestra el panel con los controles.
func _on_como_jugar_pressed() -> void:
	how_to_panel.visible = true


## Cierra el panel de controles.
func _on_cerrar_pressed() -> void:
	how_to_panel.visible = false
