extends Area2D

@export_file("*.tscn") var destination_scene: String
@export var entry_position: Vector2
@export var portal_label: String = "ESCENA"
@export var required_stage_id: String = ""

var used: bool = false
var _label: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_visual()
	_create_label()


func _on_body_entered(body: Node2D) -> void:
	if used or not body is CharacterBody2D:
		return
	if not required_stage_id.is_empty() and not GameState.is_stage_cleared(required_stage_id):
		_label.text = "DERROTA TODOS"
		return
	if destination_scene.is_empty() or not ResourceLoader.exists(destination_scene):
		push_error("El portal '%s' no tiene una escena destino válida." % name)
		return

	used = true
	monitoring = false
	GameState.transition_to_scene(
		get_tree(),
		destination_scene,
		entry_position,
		int(body.get("health"))
	)


func _create_label() -> void:
	var label_panel := PanelContainer.new()
	label_panel.name = "PortalLabel"
	label_panel.position = Vector2(-110.0, -112.0)
	label_panel.size = Vector2(220.0, 32.0)
	label_panel.z_index = 10
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#101a2de8")
	panel_style.border_color = Color("#70eaff")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_right = 8.0
	label_panel.add_theme_stylebox_override("panel", panel_style)

	_label = Label.new()
	_label.text = portal_label
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("#e9fcff"))
	label_panel.add_child(_label)
	add_child(label_panel)


func _create_visual() -> void:
	var visual := Node2D.new()
	visual.name = "PortalVisual"
	visual.z_index = 1
	add_child(visual)

	var outer_shadow := Polygon2D.new()
	outer_shadow.polygon = _ellipse_points(Vector2(44.0, 77.0), 48)
	outer_shadow.color = Color("#050b16")
	visual.add_child(outer_shadow)

	var outer_glow := _add_ellipse_line(visual, Vector2(41.0, 73.0), Color("#4b7dff66"), 11.0)
	outer_glow.z_index = 1
	var outer_ring := _add_ellipse_line(visual, Vector2(38.0, 69.0), Color("#88dfff"), 4.0)
	outer_ring.z_index = 2

	var opening := Polygon2D.new()
	opening.polygon = _ellipse_points(Vector2(31.0, 61.0), 48)
	opening.color = Color("#102d4be8")
	visual.add_child(opening)

	var inner_ring := _add_ellipse_line(visual, Vector2(27.0, 54.0), Color("#56e7ffc9"), 2.0)
	inner_ring.z_index = 3
	var inner_echo := _add_ellipse_line(visual, Vector2(19.0, 40.0), Color("#b074ff99"), 2.0)
	inner_echo.z_index = 3

	for rune_index in range(6):
		var angle := TAU * float(rune_index) / 6.0
		var rune := Polygon2D.new()
		rune.polygon = PackedVector2Array([
			Vector2(0.0, -4.0),
			Vector2(3.0, 0.0),
			Vector2(0.0, 4.0),
			Vector2(-3.0, 0.0),
		])
		rune.position = Vector2(cos(angle) * 43.0, sin(angle) * 72.0)
		rune.color = Color("#f4e7a0")
		rune.z_index = 3
		visual.add_child(rune)

	var pulse := visual.create_tween().set_loops()
	pulse.tween_property(visual, "scale", Vector2(1.04, 1.02), 0.9)
	pulse.tween_property(visual, "scale", Vector2(0.97, 0.98), 0.9)

	var echo_pulse := inner_echo.create_tween().set_loops()
	echo_pulse.tween_property(inner_echo, "rotation", TAU, 5.0)


func _add_ellipse_line(
	parent: Node2D,
	radii: Vector2,
	line_color: Color,
	line_width: float
) -> Line2D:
	var line := Line2D.new()
	line.points = _ellipse_points(radii, 48)
	line.closed = true
	line.width = line_width
	line.default_color = line_color
	line.antialiased = true
	parent.add_child(line)
	return line


func _ellipse_points(radii: Vector2, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
