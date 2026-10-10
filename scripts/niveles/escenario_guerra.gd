extends Node2D

const RETRO_TRANSITION = preload("res://scripts/niveles/transicion_retro.gd")
const DEFEAT_SCREEN = preload("res://scripts/niveles/pantalla_derrota.gd")
const GAME_OVER_TEXTURE: Texture2D = preload("res://assets/personajes/cinematicas/Game_over_2.jpg.jpeg")

@onready var background: Sprite2D = $Fondo
@onready var player: CharacterBody2D = $jugador
@onready var ant_left: Area2D = $HormigaIzquierda
@onready var ant_right: Area2D = $HormigaDerecha

var game_finished: bool = false
var remaining_ants: int = 0
var player_health_bar: ProgressBar
var player_health_tween: Tween
var health_bar_initialized: bool = false
var enemy_count_label: Label


func _ready() -> void:
	GameState.enter_stage(player, "guerra")
	get_viewport().size_changed.connect(_fit_background)
	_fit_background()
	_create_hud()
	player.health_changed.connect(_on_player_health_changed)
	player.defeated.connect(_on_player_defeated)
	_on_player_health_changed(player.health, player.max_health)

	for ant_data: Array in [
		[ant_left, "hormiga_izquierda"],
		[ant_right, "hormiga_derecha"],
	]:
		var ant: Area2D = ant_data[0]
		var ant_id: String = ant_data[1]
		if not GameState.should_spawn_enemy("guerra", ant_id):
			ant.queue_free()
			continue
		remaining_ants += 1
		ant.set_target(player)
		ant.defeated.connect(_on_ant_defeated.bind(ant_id))
	_update_enemy_count()


func _fit_background() -> void:
	var viewport_size := get_viewport_rect().size
	var texture_size := background.texture.get_size()
	var cover_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	background.position = viewport_size * 0.5
	background.scale = Vector2.ONE * cover_scale


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var hud := Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)

	var label := Label.new()
	label.text = "JUGADOR"
	label.position = Vector2(24.0, 12.0)
	label.size = Vector2(360.0, 28.0)
	label.add_theme_color_override("font_color", Color("#fff4e8"))
	label.add_theme_font_size_override("font_size", 20)
	hud.add_child(label)

	player_health_bar = ProgressBar.new()
	player_health_bar.show_percentage = false
	player_health_bar.position = Vector2(24.0, 40.0)
	player_health_bar.size = Vector2(360.0, 32.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#63d471")
	fill.set_corner_radius_all(4)
	player_health_bar.add_theme_stylebox_override("fill", fill)
	hud.add_child(player_health_bar)

	enemy_count_label = Label.new()
	enemy_count_label.anchor_left = 1.0
	enemy_count_label.anchor_right = 1.0
	enemy_count_label.offset_left = -260.0
	enemy_count_label.offset_right = -24.0
	enemy_count_label.offset_top = 18.0
	enemy_count_label.offset_bottom = 48.0
	enemy_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemy_count_label.add_theme_color_override("font_color", Color("#fff4e8"))
	enemy_count_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(enemy_count_label)


func _update_enemy_count() -> void:
	enemy_count_label.text = "HORMIGAS: %d" % remaining_ants


func _on_player_health_changed(current: int, maximum: int) -> void:
	player_health_bar.max_value = maximum
	if not health_bar_initialized:
		player_health_bar.value = current
		health_bar_initialized = true
		return
	if player_health_tween != null and player_health_tween.is_running():
		player_health_tween.kill()
	player_health_tween = create_tween()
	player_health_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	player_health_tween.tween_property(player_health_bar, "value", current, 0.45)


func _on_ant_defeated(ant_id: String) -> void:
	GameState.mark_enemy_defeated("guerra", ant_id)
	remaining_ants -= 1
	_update_enemy_count()
	if remaining_ants == 0:
		GameState.mark_stage_cleared("guerra")


func _on_player_defeated() -> void:
	if game_finished:
		return
	game_finished = true
	RETRO_TRANSITION.transition_to(get_tree(), "", _show_defeat_screen)


func _show_defeat_screen() -> void:
	DEFEAT_SCREEN.show(
		self,
		GAME_OVER_TEXTURE,
		_restart_game,
		_exit_game,
		0.465,
		0.535
	)


func _restart_game() -> void:
	get_tree().paused = false
	GameState.restart_from_start(get_tree(), player.max_health)


func _exit_game() -> void:
	get_tree().quit()
