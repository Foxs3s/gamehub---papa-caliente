extends Node2D

const RETRO_TRANSITION = preload("res://scripts/niveles/transicion_retro.gd")
const DEFEAT_SCREEN = preload("res://scripts/niveles/pantalla_derrota.gd")
const GAME_OVER_TEXTURE: Texture2D = preload("res://assets/personajes/cinematicas/Game_over_3.jpg.jpeg")
const BOSS_TIME_LIMIT: float = 35.0

@onready var background: Sprite2D = $Fondo
@onready var player: CharacterBody2D = $jugador
@onready var boss: Area2D = $BossEmbestida

var player_health_bar: ProgressBar
var boss_health_bar: ProgressBar
var boss_status_label: Label
var timer_label: Label
var player_health_tween: Tween
var boss_health_tween: Tween
var player_health_initialized: bool = false
var boss_health_initialized: bool = false
var game_finished: bool = false
var boss_defeated: bool = false
var boss_is_charging: bool = true
var time_remaining: float = BOSS_TIME_LIMIT


func _ready() -> void:
	GameState.enter_stage(player, "boss_embestida")
	get_viewport().size_changed.connect(_fit_background)
	_fit_background()
	_create_hud()

	player.health_changed.connect(_on_player_health_changed)
	player.defeated.connect(_on_player_defeated)
	if GameState.is_boss_defeated("boss_embestida"):
		boss_defeated = true
		GameState.mark_stage_cleared("boss_embestida")
		boss.hide()
		boss.monitoring = false
		boss.hitbox.set_deferred("disabled", true)
		boss.health = 0
		boss.remove_from_group("boss")
		boss_status_label.text = "JEFE DERROTADO"
	else:
		boss.set_target(player)
		boss.health_changed.connect(_on_boss_health_changed)
		boss.phase_changed.connect(_on_boss_phase_changed)
		boss.charge_updated.connect(_on_charge_updated)
		boss.defeated.connect(_on_boss_defeated)
	_on_player_health_changed(player.health, player.max_health)
	if boss_defeated:
		boss_status_label.text = "JEFE DERROTADO"
		boss_health_bar.hide()
		timer_label.hide()
	else:
		_on_boss_health_changed(boss.health, boss.max_health)
		_on_boss_phase_changed("charging")
		_on_charge_updated(boss.phase_timer)
	_update_timer_label()


func _process(delta: float) -> void:
	if game_finished or boss_defeated or time_remaining <= 0.0:
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	_update_timer_label()
	if time_remaining <= 0.0:
		player.explode()


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

	player_health_bar = _create_health_bar(hud, false, Color("#63d471"))
	player_health_bar.offset_left = 24.0
	player_health_bar.offset_top = 40.0
	player_health_bar.offset_right = 384.0
	player_health_bar.offset_bottom = 72.0

	boss_status_label = _create_label(hud, "BOSS EMBESTIDA", true)
	boss_status_label.offset_left = -304.0
	boss_status_label.offset_top = 12.0
	boss_status_label.offset_right = -24.0
	boss_status_label.offset_bottom = 36.0

	boss_health_bar = _create_health_bar(hud, true, Color("#e34b4b"))
	boss_health_bar.offset_left = -304.0
	boss_health_bar.offset_top = 40.0
	boss_health_bar.offset_right = -24.0
	boss_health_bar.offset_bottom = 64.0

	timer_label = _create_label(hud, "", true)
	timer_label.offset_left = -304.0
	timer_label.offset_top = 72.0
	timer_label.offset_right = -24.0
	timer_label.offset_bottom = 96.0

	var controls_label := _create_label(hud, "SALTA durante la embestida  |  GOLPEA durante la carga o aturdimiento", false)
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
	label.add_theme_font_size_override("font_size", 18)
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT if align_right else Control.PRESET_TOP_LEFT)
	parent.add_child(label)
	return label


func _create_health_bar(parent: Control, align_right: bool, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT if align_right else Control.PRESET_TOP_LEFT)

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color("#292331")
	background_style.set_border_width_all(2)
	background_style.border_color = Color("#fff4e8")
	background_style.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", background_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)

	parent.add_child(bar)
	return bar


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


func _on_boss_health_changed(current: int, maximum: int) -> void:
	boss_health_bar.max_value = maximum
	if not boss_health_initialized:
		boss_health_bar.value = current
		boss_health_initialized = true
		return

	if boss_health_tween != null and boss_health_tween.is_running():
		boss_health_tween.kill()
	boss_health_tween = create_tween()
	boss_health_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	boss_health_tween.tween_property(boss_health_bar, "value", current, 0.45)


func _update_timer_label() -> void:
	var seconds_left := ceili(time_remaining)
	timer_label.text = "TIEMPO %02d:%02d" % [floori(float(seconds_left) / 60.0), seconds_left % 60]
	timer_label.add_theme_color_override(
		"font_color", Color("#ff6464") if seconds_left <= 10 else Color("#fff4e8")
	)


func _on_boss_phase_changed(phase: String) -> void:
	if boss_status_label == null:
		return
	boss_is_charging = phase == "charging"
	match phase:
		"charging":
			boss_status_label.text = "¡CARGANDO EMBESTIDA!"
			boss_status_label.add_theme_color_override("font_color", Color("#ffb35c"))
		"dashing":
			boss_status_label.text = "¡ESQUIVA!"
			boss_status_label.add_theme_color_override("font_color", Color("#ff6464"))
		"stunned":
			boss_status_label.text = "¡BOSS ATURDIDO: GOLPEA!"
			boss_status_label.add_theme_color_override("font_color", Color("#8be9fd"))


func _on_charge_updated(time_left: float) -> void:
	if boss_status_label != null and boss_is_charging:
		boss_status_label.text = "¡CARGANDO EMBESTIDA: %.1f!" % time_left
		var warning_color := Color("#ff4545") if int(time_left * 8.0) % 2 == 0 else Color("#ffb35c")
		boss_status_label.add_theme_color_override("font_color", warning_color)


func _on_boss_defeated() -> void:
	boss_defeated = true
	GameState.mark_boss_defeated("boss_embestida")
	GameState.mark_stage_cleared("boss_embestida")
	GameState.add_coins(130)
	boss_status_label.text = "¡JEFE DERROTADO! PUEDES REGRESAR"
	boss_health_bar.hide()


func _on_player_defeated() -> void:
	if game_finished:
		return

	game_finished = true
	RETRO_TRANSITION.transition_to(get_tree(), "", _show_game_over_screen)


func _show_game_over_screen() -> void:
	DEFEAT_SCREEN.show(
		self,
		GAME_OVER_TEXTURE,
		_restart_game,
		_exit_game,
		0.28,
		0.35,
		true
	)


func _show_end_screen(title_text: String) -> void:
	if game_finished:
		return

	game_finished = true
	var end_layer := CanvasLayer.new()
	end_layer.name = "EndScreen"
	end_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(end_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.02, 0.05, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420.0, 220.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#292331")
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color("#d8a45c")
	panel_style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	panel.add_child(content)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#fff4e8"))
	content.add_child(title)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	content.add_child(buttons)

	var restart_button := Button.new()
	restart_button.text = "Reiniciar"
	restart_button.custom_minimum_size = Vector2(160.0, 56.0)
	restart_button.add_theme_font_size_override("font_size", 24)
	restart_button.pressed.connect(_restart_game)
	buttons.add_child(restart_button)

	var exit_button := Button.new()
	exit_button.text = "Salir"
	exit_button.custom_minimum_size = Vector2(160.0, 56.0)
	exit_button.add_theme_font_size_override("font_size", 24)
	exit_button.pressed.connect(_exit_game)
	buttons.add_child(exit_button)

	get_tree().paused = true


func _restart_game() -> void:
	get_tree().paused = false
	GameState.restart_from_start(get_tree(), player.max_health)


func _exit_game() -> void:
	get_tree().quit()
