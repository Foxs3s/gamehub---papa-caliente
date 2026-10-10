extends Node2D

const RETRO_TRANSITION = preload("res://scripts/niveles/transicion_retro.gd")
const DEFEAT_SCREEN = preload("res://scripts/niveles/pantalla_derrota.gd")
const GAME_OVER_TEXTURE: Texture2D = preload("res://assets/personajes/cinematicas/Game_over_3.jpg.jpeg")

@onready var background: Sprite2D = $Fondo
@onready var player: CharacterBody2D = $jugador
@onready var boss: Area2D = $BossEmbestida

var player_health_bar: ProgressBar
var boss_health_bar: ProgressBar
var boss_status_label: Label
var game_finished: bool = false
var boss_is_charging: bool = true


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_background)
	_fit_background()
	_create_hud()

	player.health_changed.connect(_on_player_health_changed)
	player.defeated.connect(_on_player_defeated)
	boss.set_target(player)
	boss.health_changed.connect(_on_boss_health_changed)
	boss.phase_changed.connect(_on_boss_phase_changed)
	boss.charge_updated.connect(_on_charge_updated)
	boss.defeated.connect(_on_boss_defeated)
	_on_player_health_changed(player.health, player.max_health)
	_on_boss_health_changed(boss.health, boss.max_health)
	_on_boss_phase_changed("charging")
	_on_charge_updated(boss.charge_duration)


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
	player_label.offset_right = 304.0
	player_label.offset_bottom = 36.0

	player_health_bar = _create_health_bar(hud, false, Color("#63d471"))
	player_health_bar.offset_left = 24.0
	player_health_bar.offset_top = 40.0
	player_health_bar.offset_right = 304.0
	player_health_bar.offset_bottom = 64.0

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

	var controls_label := _create_label(hud, "SALTA durante la embestida  |  GOLPEA durante la carga", false)
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
	player_health_bar.value = current


func _on_boss_health_changed(current: int, maximum: int) -> void:
	boss_health_bar.max_value = maximum
	boss_health_bar.value = current


func _on_boss_phase_changed(phase: String) -> void:
	if boss_status_label == null:
		return
	boss_is_charging = phase == "charging"
	boss_status_label.text = "¡CARGANDO EMBESTIDA!" if boss_is_charging else "¡ESQUIVA!"
	boss_status_label.add_theme_color_override(
		"font_color",
		Color("#ffb35c") if boss_is_charging else Color("#ff6464")
	)


func _on_charge_updated(time_left: float) -> void:
	if boss_status_label != null and boss_is_charging:
		boss_status_label.text = "¡CARGANDO! %.1f" % time_left


func _on_boss_defeated() -> void:
	boss_status_label.text = "BOSS DERROTADO"
	RETRO_TRANSITION.transition_to(get_tree(), "", _show_end_screen.bind("YOU WIN"))


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
	RETRO_TRANSITION.transition_to(get_tree(), "res://scenes/Niveles/introduccion.tscn")


func _exit_game() -> void:
	get_tree().quit()
