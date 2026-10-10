extends Node2D

const RETRO_TRANSITION = preload("res://scripts/niveles/transicion_retro.gd")
const DEFEAT_SCREEN = preload("res://scripts/niveles/pantalla_derrota.gd")
const GAME_OVER_TEXTURE: Texture2D = preload("res://assets/personajes/cinematicas/Game_over_1.jpg.jpeg")

@onready var background: Sprite2D = $Fondo
@onready var player: CharacterBody2D = $jugador
@onready var ladybug_one: Area2D = $Mariquita1
@onready var ladybug_two: Area2D = $Mariquita2

var player_health_bar: ProgressBar
var enemy_count_label: Label
var player_health_tween: Tween
var player_health_initialized: bool = false
var remaining_ladybugs: int = 0
var game_finished: bool = false


func _ready() -> void:
	GameState.enter_stage(player, "sendero_soleado")
	get_viewport().size_changed.connect(_fit_background)
	_fit_background()
	_create_hud()

	player.health_changed.connect(_on_player_health_changed)
	player.defeated.connect(_on_player_defeated)
	_on_player_health_changed(player.health, player.max_health)

	for enemy_data: Array in [
		[ladybug_one, "mariquita_izquierda"],
		[ladybug_two, "mariquita_derecha"],
	]:
		var ladybug: Area2D = enemy_data[0]
		var enemy_id: String = enemy_data[1]
		if not GameState.should_spawn_enemy("sendero_soleado", enemy_id):
			ladybug.queue_free()
			continue
		remaining_ladybugs += 1
		ladybug.set_target(player)
		ladybug.defeated.connect(_on_ladybug_defeated.bind(enemy_id))

	_update_enemy_count()


func _fit_background() -> void:
	var viewport_size := get_viewport_rect().size
	var texture_size := background.texture.get_size()
	var cover_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)

	background.centered = true
	background.position = viewport_size * 0.5
	background.scale = Vector2.ONE * cover_scale


func _create_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUD"
	add_child(hud_layer)

	var hud := Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)

	var player_label := _create_label(hud, "JUGADOR", false)
	player_label.offset_left = 24.0
	player_label.offset_top = 12.0
	player_label.offset_right = 384.0
	player_label.offset_bottom = 36.0

	player_health_bar = ProgressBar.new()
	player_health_bar.show_percentage = false
	player_health_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	player_health_bar.offset_left = 24.0
	player_health_bar.offset_top = 40.0
	player_health_bar.offset_right = 384.0
	player_health_bar.offset_bottom = 72.0
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color("#292331")
	background_style.set_border_width_all(2)
	background_style.border_color = Color("#fff4e8")
	background_style.set_corner_radius_all(5)
	player_health_bar.add_theme_stylebox_override("background", background_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#63d471")
	fill_style.set_corner_radius_all(4)
	player_health_bar.add_theme_stylebox_override("fill", fill_style)
	hud.add_child(player_health_bar)

	enemy_count_label = _create_label(hud, "", true)
	enemy_count_label.offset_left = -360.0
	enemy_count_label.offset_top = 18.0
	enemy_count_label.offset_right = -24.0
	enemy_count_label.offset_bottom = 48.0

	var controls_label := _create_label(
		hud,
		"A/D o ←/→: mover   |   ESPACIO/W: saltar   |   F: golpear   |   E: tienda   |   G: Papamax",
		false
	)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_label.offset_left = 24.0
	controls_label.offset_top = -48.0
	controls_label.offset_right = -24.0
	controls_label.offset_bottom = -16.0


func _create_label(parent: Control, label_text: String, align_right: bool) -> Label:
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if align_right else HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_color_override("font_color", Color("#fff4e8"))
	label.add_theme_font_size_override("font_size", 20)
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT if align_right else Control.PRESET_TOP_LEFT)
	parent.add_child(label)
	return label


func _on_player_health_changed(current: int, maximum: int) -> void:
	player_health_bar.max_value = maximum
	if not player_health_initialized:
		player_health_bar.value = current
		player_health_initialized = true
		return

	if player_health_tween != null and player_health_tween.is_running():
		player_health_tween.kill()
	player_health_tween = create_tween()
	player_health_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	player_health_tween.tween_property(player_health_bar, "value", current, 0.45)


func _on_ladybug_defeated(enemy_id: String) -> void:
	if game_finished:
		return

	GameState.mark_enemy_defeated("sendero_soleado", enemy_id)
	remaining_ladybugs -= 1
	_update_enemy_count()
	if remaining_ladybugs == 0:
		GameState.mark_stage_cleared("sendero_soleado")


func _update_enemy_count() -> void:
	enemy_count_label.text = "MARIQUITAS: %d" % remaining_ladybugs


func _on_player_defeated() -> void:
	if game_finished:
		return

	game_finished = true
	RETRO_TRANSITION.transition_to(get_tree(), "", _show_defeat_screen)


func _show_defeat_screen() -> void:
	DEFEAT_SCREEN.show(
		self,
		GAME_OVER_TEXTURE,
		_restart_level,
		_exit_game,
		0.90,
		0.99
	)


func _restart_level() -> void:
	get_tree().paused = false
	GameState.restart_from_start(get_tree(), player.max_health)


func _exit_game() -> void:
	get_tree().quit()
