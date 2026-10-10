extends RefCounted

const ROW_COUNT: int = 12
const COVER_COLOR_A: Color = Color("#17121f")
const COVER_COLOR_B: Color = Color("#292331")


static func transition_to(
	tree: SceneTree,
	scene_path: String,
	on_covered: Callable = Callable()
) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1000
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)

	var rows: Array[ColorRect] = []
	var viewport_size := Vector2(tree.root.size)
	var row_height := ceilf(viewport_size.y / ROW_COUNT)
	for index in range(ROW_COUNT):
		var row := ColorRect.new()
		row.color = COVER_COLOR_A if index % 2 == 0 else COVER_COLOR_B
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.position = Vector2(0.0, index * row_height)
		row.size = Vector2(0.0, row_height + 1.0)
		layer.add_child(row)
		rows.append(row)

	if scene_path.is_empty() and not on_covered.is_valid():
		layer.queue_free()
		return

	tree.paused = true
	var cover_tween := layer.create_tween()
	cover_tween.set_parallel(true)
	for index in range(ROW_COUNT):
		cover_tween.tween_property(
			rows[index],
			"size:x",
			viewport_size.x,
			0.07
		).set_delay(index * 0.025)
	await cover_tween.finished

	if scene_path.is_empty():
		if on_covered.is_valid():
			tree.paused = false
			on_covered.call()
	else:
		var change_error := tree.change_scene_to_file(scene_path)
		if change_error != OK:
			push_error("No se pudo cambiar a la escena '%s' (error %d)." % [scene_path, change_error])
			tree.paused = false
			layer.queue_free()
			return
		await tree.scene_changed
		tree.paused = false
		if on_covered.is_valid():
			on_covered.call()

	var reveal_tween := layer.create_tween()
	reveal_tween.set_parallel(true)
	for index in range(ROW_COUNT):
		reveal_tween.tween_property(
			rows[index],
			"size:x",
			0.0,
			0.07
		).set_delay((ROW_COUNT - index - 1) * 0.025)
	await reveal_tween.finished
	layer.queue_free()
