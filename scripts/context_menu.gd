class_name ContextMenu
extends Control

## Menú contextual que aparece al tocar una construcción: muestra nombre, nivel,
## botón Mejorar (con costo) y botón Vender (con reembolso). Los botones llaman
## upgrade()/sell() sobre la construcción objetivo.

## Construcción que se está inspeccionando (pared, torre/aliado o edificio).
var target: Node

var _panel: PanelContainer
var _title: Label
var _upgrade_btn: Button
var _sell_btn: Button


func _ready() -> void:
	visible = false
	_build_ui()


## Arma el panel, los textos y los botones (todo por código, sin .tscn).
func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.04, 0.95)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", Color(1, 1, 1))
	box.add_child(_title)

	_upgrade_btn = Button.new()
	_upgrade_btn.pressed.connect(_on_upgrade_pressed)
	box.add_child(_upgrade_btn)

	_sell_btn = Button.new()
	_sell_btn.pressed.connect(_on_sell_pressed)
	box.add_child(_sell_btn)


## Muestra el menú para `node`, con sus datos actuales, cerca de su posición.
func show_for(node: Node) -> void:
	target = node
	_refresh()
	visible = true


## Esconde el menú y suelta el objetivo.
func hide_menu() -> void:
	visible = false
	target = null


## Actualiza textos y estado de los botones según el objetivo.
func _refresh() -> void:
	if target == null or not is_instance_valid(target):
		hide_menu()
		return
	var lvl: int = target.level
	_title.text = "%s · Nv %d" % [target.display_name(), lvl]
	# Botón Mejorar: solo si el tipo se puede mejorar y no está al máximo.
	if target.is_upgradable() and lvl < 3:
		_upgrade_btn.visible = true
		_upgrade_btn.text = "Mejorar $%d" % target.upgrade_cost()
		_upgrade_btn.disabled = not target.can_upgrade()
	else:
		_upgrade_btn.visible = false
	# Botón Vender: siempre, con el reembolso.
	_sell_btn.text = "Vender +$%d" % target.sell_value()
	_reposition()


## Ubica el panel pegado a la construcción (clampado dentro de la pantalla).
func _reposition() -> void:
	_panel.reset_size()
	size = _panel.size
	var anchor: Vector2 = Vector2.ZERO
	if target is Node2D:
		anchor = target.get_global_transform_with_canvas().origin
	var view := get_viewport_rect().size
	var pos := anchor + Vector2(20.0, -size.y - 24.0)
	position = Vector2(
		clampf(pos.x, 8.0, view.x - size.x - 8.0),
		clampf(pos.y, 8.0, view.y - size.y - 8.0)
	)


## Al tocar Mejorar: intenta mejorar y refresca los botones.
func _on_upgrade_pressed() -> void:
	if target != null and is_instance_valid(target) and target.upgrade():
		_refresh()


## Al tocar Vender: vende la construcción y cierra el menú.
func _on_sell_pressed() -> void:
	if target != null and is_instance_valid(target):
		target.sell()
	hide_menu()
