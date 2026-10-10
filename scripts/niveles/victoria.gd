extends Control

const RETRO_TRANSITION = preload("res://scripts/niveles/transicion_retro.gd")
const MENU_SCENE: String = "res://scenes/ui/menu.tscn"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_create_background()
	_create_victory_panel()


func _create_background() -> void:
	var background := ColorRect.new()
	background.color = Color("#111827")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var glow := Panel.new()
	glow.anchor_left = 0.2
	glow.anchor_top = 0.14
	glow.anchor_right = 0.8
	glow.anchor_bottom = 0.86
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color("#1c435566")
	glow_style.set_corner_radius_all(240)
	glow.add_theme_stylebox_override("panel", glow_style)
	add_child(glow)


func _create_victory_panel() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 350.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#202638")
	panel_style.border_color = Color("#f4c95d")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 34.0
	panel_style.content_margin_right = 34.0
	panel_style.content_margin_top = 30.0
	panel_style.content_margin_bottom = 30.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)

	var emblem := Label.new()
	emblem.text = "✦  ✦  ✦"
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.add_theme_font_size_override("font_size", 26)
	emblem.add_theme_color_override("font_color", Color("#f4c95d"))
	content.add_child(emblem)

	var title := Label.new()
	title.text = "¡HAS GANADO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#fff4e8"))
	title.add_theme_color_override("font_shadow_color", Color("#0b101c"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	content.add_child(title)

	var message := Label.new()
	message.text = "Derrotaste al jefe final y salvaste el reino."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color("#c8d3e2"))
	content.add_child(message)

	var menu_button := Button.new()
	menu_button.text = "VOLVER AL MENÚ"
	menu_button.custom_minimum_size = Vector2(280.0, 52.0)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.add_theme_font_size_override("font_size", 19)
	menu_button.pressed.connect(_return_to_menu)
	content.add_child(menu_button)

	var exit_button := Button.new()
	exit_button.text = "SALIR DEL JUEGO"
	exit_button.custom_minimum_size = Vector2(280.0, 44.0)
	exit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exit_button.add_theme_font_size_override("font_size", 16)
	exit_button.pressed.connect(_exit_game)
	content.add_child(exit_button)


func _return_to_menu() -> void:
	GameState.start_new_run()
	RETRO_TRANSITION.transition_to(get_tree(), MENU_SCENE)


func _exit_game() -> void:
	get_tree().quit()
