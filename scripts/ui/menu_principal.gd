extends Control

const MENU_BACKGROUND: Texture2D = preload("res://assets/interfaz/fondo_menuj.jpg")

func _ready() -> void:
	MusicManager.set_context("menu")
	set_anchors_preset(PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var play_button := _create_art_button("Play", Vector2(0.412, 0.57), Vector2(0.589, 0.711))
	play_button.pressed.connect(_on_play_pressed)

	var exit_button := _create_art_button("Salir", Vector2(0.466, 0.764), Vector2(0.535, 0.887))
	exit_button.pressed.connect(_on_salir_pressed)


func _create_art_button(description: String, top_left: Vector2, bottom_right: Vector2) -> Button:
	var button := Button.new()
	button.name = "%sButton" % description
	button.tooltip_text = description
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	button.anchor_left = top_left.x
	button.anchor_top = top_left.y
	button.anchor_right = bottom_right.x
	button.anchor_bottom = bottom_right.y
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(1.0, 1.0, 1.0, 0.2)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", focus_style)
	button.add_theme_stylebox_override("focus", focus_style)
	add_child(button)
	return button

func _on_play_pressed() -> void:
	print("Cargando juego...")
	GameState.begin_new_run(get_tree())

func _on_salir_pressed() -> void:
	get_tree().quit()