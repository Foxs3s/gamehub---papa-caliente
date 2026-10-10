extends RefCounted


static func show(
	owner: Node2D,
	world_position: Vector2,
	amount: int,
	color: Color,
	is_critical: bool = false
) -> void:
	if not is_instance_valid(owner) or amount <= 0:
		return

	var scene_root := owner.get_tree().current_scene
	if scene_root == null:
		return

	var layer := CanvasLayer.new()
	layer.layer = 10
	scene_root.add_child(layer)

	var label := Label.new()
	label.text = "CRÍTICO\n-%d" % amount if is_critical else "-%d" % amount
	label.position = owner.get_viewport().get_canvas_transform() * world_position
	label.position += Vector2(-45.0, -28.0)
	label.size = Vector2(90.0, 32.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(
		"font_color", Color("#ffcf5c") if is_critical else color
	)
	label.add_theme_color_override("font_shadow_color", Color("#292331"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 28 if is_critical else 24)
	layer.add_child(label)

	var tween := label.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 42.0, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(layer.queue_free)
