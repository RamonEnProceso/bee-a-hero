class_name GameOverScreen
extends CanvasLayer

## Pantalla de derrota: muestra la oleada alcanzada y la mejor oleada (guardada
## en user:// con ConfigFile). Botones Reintentar y Menú. process_mode = When
## Paused para funcionar con el juego pausado al morir la reina.

const SAVE_PATH := "user://record.cfg"

@onready var wave_label: Label = $Center/Card/VBox/WaveLabel
@onready var best_label: Label = $Center/Card/VBox/BestLabel


func _ready() -> void:
	visible = false
	$Center/Card/VBox/ReintentarButton.pressed.connect(_on_reintentar_pressed)
	$Center/Card/VBox/MenuButton.pressed.connect(_on_menu_pressed)


## Muestra el resultado de la derrota y actualiza el récord si hizo falta.
func show_game_over(wave: int) -> void:
	var best := _load_best()
	var is_new_record := wave > best
	if is_new_record:
		best = wave
		_save_best(best)
	wave_label.text = "Llegaste a la oleada %d" % wave
	best_label.text = "Mejor oleada: %d" % best
	if is_new_record:
		best_label.text += "  (¡nuevo récord!)"
	visible = true


## Lee la mejor oleada guardada (0 si no hay récord todavía).
func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		return int(cfg.get_value("record", "best_wave", 0))
	return 0


## Guarda la mejor oleada en user:// (en Web se persiste en el navegador).
func _save_best(wave: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("record", "best_wave", wave)
	cfg.save(SAVE_PATH)


func _on_reintentar_pressed() -> void:
	Game.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	Game.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
