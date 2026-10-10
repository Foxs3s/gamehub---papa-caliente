extends Control

const STORE_TEXTURE: Texture2D = preload("res://assets/items/tienda/tienda.jpg.jpeg")
const COIN_TEXTURE: Texture2D = preload("res://assets/items/tienda/PapuCoin (1).png")
const SHOP_SERVICE = preload("res://scripts/tienda/servicio_tienda.gd")
const ITEMS: Array[Dictionary] = [
	{
		"id": "corazon",
		"description": "Corazon extra: +20 de vida maxima y restaura tu salud.",
	},
	{
		"id": "espada",
		"description": "Espada: +4 de dano normal y critico, con 5% de probabilidad critica.",
	},
	{
		"id": "papamax",
		"description": "Papamax: bomba consumible de 16 de dano, o 17-19 si es critica. Pulsa G.",
	},
]

var _artwork: TextureRect
var _balance_label: Label
var _balance_background: Panel
var _status_label: Label
var _player: CharacterBody2D
var _previous_music_context: String = ""
var _price_labels: Dictionary = {}
var _price_backgrounds: Dictionary = {}
var _price_coins: Dictionary = {}
var _purchase_buttons: Dictionary = {}
var _image_origin: Vector2 = Vector2.ZERO
var _image_size: float = 0.0


func open_for_player(player: CharacterBody2D) -> void:
	_player = player
	_previous_music_context = GameState.current_stage_id
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	GameState.coins_changed.connect(_refresh_store)
	GameState.inventory_changed.connect(_refresh_store)
	_layout_artwork()
	_refresh_store()
	get_tree().paused = true
	MusicManager.set_context("store")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_artwork):
		_layout_artwork()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#100d15")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_artwork = TextureRect.new()
	_artwork.texture = STORE_TEXTURE
	_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork.stretch_mode = TextureRect.STRETCH_SCALE
	_artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_artwork)

	_balance_background = Panel.new()
	_balance_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var balance_style := StyleBoxFlat.new()
	balance_style.bg_color = Color("#17131c")
	balance_style.set_corner_radius_all(4)
	_balance_background.add_theme_stylebox_override("panel", balance_style)
	add_child(_balance_background)

	_balance_label = _create_overlay_label(26, Color("#ffe082"))
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for item_index in range(ITEMS.size()):
		var item: Dictionary = ITEMS[item_index]
		var item_id: String = item["id"]
		var price_background := Panel.new()
		price_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var price_style := StyleBoxFlat.new()
		price_style.bg_color = Color("#17131c")
		price_style.set_corner_radius_all(5)
		price_background.add_theme_stylebox_override("panel", price_style)
		add_child(price_background)
		price_background.set_meta("item_id", item_id)
		_price_backgrounds[item_id] = price_background

		var price_coin := TextureRect.new()
		price_coin.texture = COIN_TEXTURE
		price_coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		price_coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		price_coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(price_coin)
		_price_coins[item_id] = price_coin

		var price_label := _create_overlay_label(25, Color("#ffd34e"))
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price_label.set_meta("item_id", item_id)
		_price_labels[item_id] = price_label

		var button := Button.new()
		button.flat = true
		button.text = ""
		button.tooltip_text = item["description"]
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _transparent_style())
		button.add_theme_stylebox_override("focus", _highlight_style(Color(1.0, 1.0, 1.0, 0.13)))
		button.add_theme_stylebox_override("hover", _highlight_style(Color(1.0, 0.82, 0.25, 0.16)))
		button.add_theme_stylebox_override("pressed", _highlight_style(Color(1.0, 0.82, 0.25, 0.28)))
		button.mouse_entered.connect(_show_item_description.bind(item))
		button.pressed.connect(_purchase_item.bind(item_id))
		add_child(button)
		button.set_meta("item_id", item_id)
		_purchase_buttons[item_id] = button

	_status_label = _create_overlay_label(25, Color("#fff4e8"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "Pulsa un articulo para comprarlo. ESC para salir."

	var close_button := Button.new()
	close_button.text = "CERRAR  X"
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", Color("#fff4e8"))
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.pressed.connect(_close)
	add_child(close_button)
	close_button.set_meta("shop_close", true)


func _layout_artwork() -> void:
	_image_size = minf(size.x, size.y)
	_image_origin = (size - Vector2.ONE * _image_size) * 0.5
	_artwork.position = _image_origin
	_artwork.size = Vector2.ONE * _image_size

	_set_image_rect(_balance_background, Vector2(0.813, 0.535), Vector2(0.06, 0.044))
	_set_image_rect(_balance_label, Vector2(0.813, 0.535), Vector2(0.06, 0.044))
	_set_image_rect(_status_label, Vector2(0.16, 0.875), Vector2(0.68, 0.065))

	var price_centers := {
		"corazon": Vector2(0.25, 0.798),
		"espada": Vector2(0.55, 0.798),
		"papamax": Vector2(0.85, 0.798),
	}
	for item_id in _price_labels:
		var center: Vector2 = price_centers[item_id]
		var price_label := _price_labels[item_id] as Label
		var price_background := _price_backgrounds[item_id] as Panel
		var price_coin := _price_coins[item_id] as TextureRect
		_set_image_rect(price_background, center, Vector2(0.15, 0.04))
		_set_image_rect(price_coin, center + Vector2(-0.047, 0.0), Vector2(0.032, 0.032))
		_set_image_rect(price_label, center + Vector2(-0.005, 0.0), Vector2(0.075, 0.04))
		price_label.add_theme_font_size_override(
			"font_size", maxi(roundi(46.0 * _image_size / 1600.0), 12)
		)

	var item_rects := {
		"corazon": [Vector2(0.045, 0.57), Vector2(0.32, 0.775)],
		"espada": [Vector2(0.34, 0.57), Vector2(0.66, 0.775)],
		"papamax": [Vector2(0.68, 0.57), Vector2(0.955, 0.775)],
	}
	for item_id in _purchase_buttons:
		var rect: Array = item_rects[item_id]
		var button := _purchase_buttons[item_id] as Button
		button.position = _image_origin + Vector2(rect[0].x, rect[0].y) * _image_size
		button.size = (Vector2(rect[1].x, rect[1].y) - rect[0]) * _image_size

	for child in get_children():
		if child is Button and child.has_meta("shop_close"):
			var close_button := child as Button
			close_button.position = _image_origin + Vector2(0.84, 0.04) * _image_size
			close_button.size = Vector2(0.12, 0.045) * _image_size
			close_button.add_theme_font_size_override(
				"font_size", maxi(roundi(40.0 * _image_size / 1600.0), 12)
			)
	_balance_label.add_theme_font_size_override(
		"font_size", maxi(roundi(48.0 * _image_size / 1600.0), 14)
	)
	_status_label.add_theme_font_size_override(
		"font_size", maxi(roundi(46.0 * _image_size / 1600.0), 13)
	)


func _create_overlay_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _set_image_rect(control: Control, center: Vector2, dimensions: Vector2) -> void:
	control.position = _image_origin + (center - dimensions * 0.5) * _image_size
	control.size = dimensions * _image_size


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(0)
	return style


func _highlight_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#ffe082")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _refresh_store(_value: int = 0) -> void:
	if is_instance_valid(_balance_label):
		_balance_label.text = str(GameState.coins)

	for item: Dictionary in ITEMS:
		var item_id: String = item["id"]
		var price_label := _price_labels.get(item_id) as Label
		var button := _purchase_buttons.get(item_id) as Button
		if price_label == null or button == null:
			continue
		price_label.text = str(SHOP_SERVICE.get_price(item_id))


func _show_item_description(item: Dictionary) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = item["description"]
		_status_label.add_theme_color_override("font_color", Color("#fff4e8"))


func _purchase_item(item_id: String) -> void:
	if SHOP_SERVICE.purchase(item_id, _player):
		_status_label.text = "Compra realizada. Gracias por tu compra."
		_status_label.add_theme_color_override("font_color", Color("#a7f3a2"))
	else:
		_status_label.text = "No tienes suficientes PapuCoin o el articulo ya esta al maximo."
		_status_label.add_theme_color_override("font_color", Color("#ff9b8f"))
	_refresh_store()


func _close() -> void:
	if GameState.coins_changed.is_connected(_refresh_store):
		GameState.coins_changed.disconnect(_refresh_store)
	if GameState.inventory_changed.is_connected(_refresh_store):
		GameState.inventory_changed.disconnect(_refresh_store)
	get_tree().paused = false
	MusicManager.set_stage_context(_previous_music_context)
	var ui_layer := get_parent() as CanvasLayer
	if ui_layer != null:
		ui_layer.queue_free()
	else:
		queue_free()
