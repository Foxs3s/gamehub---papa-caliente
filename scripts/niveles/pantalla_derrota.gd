extends RefCounted


static func show(
	owner: Node,
	texture: Texture2D,
	restart_action: Callable,
	exit_action: Callable,
	buttons_top: float,
	buttons_bottom: float,
	vertical_buttons: bool = false
) -> void:
	var layer := CanvasLayer.new()
	layer.name = "EndScreen"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	owner.add_child(layer)

	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(screen)

	var background := TextureRect.new()
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(background)

	var restart_button: Button
	var exit_button: Button
	if vertical_buttons:
		restart_button = _create_image_button(
			screen, 0.38, 0.62, buttons_top, buttons_bottom, "Reiniciar", restart_action
		)
		exit_button = _create_image_button(
			screen,
			0.38,
			0.62,
			buttons_bottom + 0.025,
			buttons_bottom + 0.09,
			"Salir",
			exit_action
		)
		restart_button.focus_neighbor_bottom = restart_button.get_path_to(exit_button)
		exit_button.focus_neighbor_top = exit_button.get_path_to(restart_button)
	else:
		restart_button = _create_image_button(
			screen, 0.31, 0.55, buttons_top, buttons_bottom, "Reiniciar", restart_action
		)
		exit_button = _create_image_button(
			screen, 0.56, 0.70, buttons_top, buttons_bottom, "Salir", exit_action
		)
		restart_button.focus_neighbor_right = restart_button.get_path_to(exit_button)
		exit_button.focus_neighbor_left = exit_button.get_path_to(restart_button)

	owner.get_tree().paused = true


static func _create_image_button(
	parent: Control,
	left_anchor: float,
	right_anchor: float,
	top_anchor: float,
	bottom_anchor: float,
	description: String,
	action: Callable
) -> Button:
	var button := Button.new()
	button.name = "%sButton" % description
	button.tooltip_text = description
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.anchor_left = left_anchor
	button.anchor_right = right_anchor
	button.anchor_top = top_anchor
	button.anchor_bottom = bottom_anchor
	button.offset_left = 0.0
	button.offset_right = 0.0
	button.offset_top = 0.0
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
	button.pressed.connect(action)
	parent.add_child(button)
	return button
