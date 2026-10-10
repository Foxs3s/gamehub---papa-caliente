extends Node

const RETRO_TRANSITION = preload("res://scripts/niveles/transicion_retro.gd")
const START_SCENE: String = "res://scenes/Niveles/sendero_soleado.tscn"
const START_POSITION: Vector2 = Vector2(576.0, 535.0)
const STARTING_HEALTH: int = -1
const MAX_ENEMY_RESPAWNS: int = 1
const STAGE_EXIT_MARGIN: float = 52.0

signal coins_changed(total: int)
signal inventory_changed

var coins: int = 0
var heart_upgrades: int = 0
var sword_owned: bool = false
var papamax_count: int = 0
var defeated_bosses: Dictionary = {}
var defeated_enemies: Dictionary = {}
var enemy_respawns: Dictionary = {}
var cleared_stages: Dictionary = {}
var player_health: int = -1
var pending_scene: String = ""
var pending_position: Vector2 = Vector2.ZERO
var current_stage_id: String = ""

var _coin_label: Label


func _ready() -> void:
	coins_changed.connect(_on_coins_changed)
	_create_coin_hud()
	_update_coin_hud()


func start_new_run() -> void:
	coins = 0
	heart_upgrades = 0
	sword_owned = false
	papamax_count = 0
	player_health = -1
	pending_scene = ""
	defeated_bosses.clear()
	defeated_enemies.clear()
	enemy_respawns.clear()
	cleared_stages.clear()
	current_stage_id = ""
	coins_changed.emit(coins)
	inventory_changed.emit()


func begin_new_run(tree: SceneTree) -> void:
	start_new_run()
	transition_to_scene(tree, START_SCENE, START_POSITION, STARTING_HEALTH)


func enter_stage(player: CharacterBody2D, stage_path: String) -> void:
	current_stage_id = stage_path
	MusicManager.set_stage_context(stage_path)
	apply_player_upgrades(player)
	if pending_scene.is_empty():
		return

	var current_scene := get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path != pending_scene:
		return

	player.global_position = pending_position
	player.velocity = Vector2.ZERO
	if player_health >= 0:
		player.health = mini(player_health, player.max_health)
		player.health_changed.emit(player.health, player.max_health)
	pending_scene = ""
	player_health = -1


func apply_player_upgrades(
	player: CharacterBody2D,
	heal_added_health: bool = false
) -> void:
	if player.has_method("apply_shop_upgrades"):
		player.call("apply_shop_upgrades", heart_upgrades, sword_owned, heal_added_health)


func should_spawn_enemy(stage_id: String, enemy_id: String) -> bool:
	var enemy_key := "%s:%s" % [stage_id, enemy_id]
	if not defeated_enemies.has(enemy_key):
		return true

	var respawns: int = enemy_respawns.get(enemy_key, 0)
	if respawns >= MAX_ENEMY_RESPAWNS:
		return false

	enemy_respawns[enemy_key] = respawns + 1
	defeated_enemies.erase(enemy_key)
	cleared_stages.erase(stage_id)
	return true


func mark_enemy_defeated(stage_id: String, enemy_id: String) -> void:
	defeated_enemies["%s:%s" % [stage_id, enemy_id]] = true


func mark_stage_cleared(stage_id: String) -> void:
	cleared_stages[stage_id] = true


func is_stage_cleared(stage_id: String) -> bool:
	return cleared_stages.has(stage_id)


func mark_boss_defeated(boss_id: String) -> void:
	defeated_bosses[boss_id] = true


func is_boss_defeated(boss_id: String) -> bool:
	return defeated_bosses.has(boss_id)


func add_coins(amount: int) -> void:
	if amount <= 0:
		push_error("La cantidad de monedas agregada debe ser mayor que cero.")
		return

	coins += amount
	coins_changed.emit(coins)
		

func spend_coins(amount: int) -> bool:
	if amount <= 0:
		push_error("El precio debe ser mayor que cero.")
		return false
	if coins < amount:
		return false

	coins -= amount
	coins_changed.emit(coins)
	return true


func transition_to_scene(
	tree: SceneTree,
	scene_path: String,
	spawn_position: Vector2,
	current_player_health: int
) -> void:
	pending_scene = scene_path
	pending_position = spawn_position
	player_health = current_player_health
	RETRO_TRANSITION.transition_to(tree, scene_path)


func try_transition_at_stage_edge(player: CharacterBody2D) -> bool:
	if not pending_scene.is_empty():
		return true

	var direction := 0
	if player.global_position.x <= STAGE_EXIT_MARGIN:
		direction = -1
	elif player.global_position.x >= get_viewport().get_visible_rect().size.x - STAGE_EXIT_MARGIN:
		direction = 1
	else:
		return false

	var scene_path := ""
	var spawn_position := Vector2.ZERO
	var transition_health: int = player.health
	var stage_is_cleared := is_stage_cleared(current_stage_id)
	match current_stage_id:
		"sendero_soleado":
			if direction > 0 and stage_is_cleared:
				scene_path = "res://scenes/Niveles/introduccion.tscn"
				spawn_position = Vector2(150.0, 535.0)
		"introduccion":
			if direction < 0:
				scene_path = START_SCENE
				spawn_position = Vector2(1000.0, 535.0)
			elif stage_is_cleared:
				scene_path = "res://scenes/Niveles/entrada_caverna.tscn"
				spawn_position = Vector2(576.0, 535.0)
				transition_health = player.max_health
		"entrada_caverna":
			if direction < 0:
				scene_path = "res://scenes/Niveles/introduccion.tscn"
				spawn_position = Vector2(1000.0, 535.0)
			elif stage_is_cleared:
				scene_path = "res://scenes/Niveles/mapa_1.tscn"
				spawn_position = Vector2(150.0, 520.0)
		"mapa_1":
			if direction < 0:
				scene_path = "res://scenes/Niveles/entrada_caverna.tscn"
				spawn_position = Vector2(1000.0, 535.0)
			elif stage_is_cleared:
				scene_path = "res://scenes/Niveles/escenario_guerra.tscn"
				spawn_position = Vector2(150.0, 535.0)
		"guerra":
			if direction < 0:
				scene_path = "res://scenes/Niveles/mapa_1.tscn"
				spawn_position = Vector2(1080.0, 520.0)
			elif stage_is_cleared:
				scene_path = "res://scenes/Niveles/boss_embestida.tscn"
				spawn_position = Vector2(1020.0, 566.0)
		"boss_embestida":
			if direction < 0:
				scene_path = "res://scenes/Niveles/escenario_guerra.tscn"
				spawn_position = Vector2(1000.0, 535.0)
			elif is_boss_defeated("boss_embestida"):
				scene_path = "res://scenes/Niveles/victoria.tscn"

	if not scene_path.is_empty():
		transition_to_scene(get_tree(), scene_path, spawn_position, transition_health)
		return true

	player.global_position.x = (
		STAGE_EXIT_MARGIN
		if direction < 0
		else get_viewport().get_visible_rect().size.x - STAGE_EXIT_MARGIN
	)
	player.velocity.x = 0.0
	return true


func restart_from_start(tree: SceneTree, max_player_health: int) -> void:
	defeated_enemies.clear()
	enemy_respawns.clear()
	cleared_stages.erase("sendero_soleado")
	cleared_stages.erase("entrada_caverna")
	cleared_stages.erase("guerra")
	pending_scene = START_SCENE
	pending_position = START_POSITION
	player_health = max_player_health
	RETRO_TRANSITION.transition_to(tree, START_SCENE)


func _create_coin_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CurrencyHUD"
	canvas.layer = 20
	add_child(canvas)

	_coin_label = Label.new()
	_coin_label.anchor_left = 1.0
	_coin_label.anchor_right = 1.0
	_coin_label.offset_left = -220.0
	_coin_label.offset_right = -24.0
	_coin_label.offset_top = 102.0
	_coin_label.offset_bottom = 138.0
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coin_label.add_theme_font_size_override("font_size", 22)
	_coin_label.add_theme_color_override("font_color", Color("#ffd34e"))
	canvas.add_child(_coin_label)

	var coin_icon := TextureRect.new()
	coin_icon.texture = preload("res://assets/items/tienda/PapuCoin (1).png")
	coin_icon.anchor_left = 1.0
	coin_icon.anchor_right = 1.0
	coin_icon.offset_left = -258.0
	coin_icon.offset_right = -222.0
	coin_icon.offset_top = 103.0
	coin_icon.offset_bottom = 139.0
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	canvas.add_child(coin_icon)

	var inventory_label := Label.new()
	inventory_label.anchor_left = 1.0
	inventory_label.anchor_right = 1.0
	inventory_label.offset_left = -244.0
	inventory_label.offset_right = -24.0
	inventory_label.offset_top = 142.0
	inventory_label.offset_bottom = 172.0
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inventory_label.add_theme_font_size_override("font_size", 18)
	inventory_label.add_theme_color_override("font_color", Color("#fff4e8"))
	inventory_label.name = "PapamaxCount"
	canvas.add_child(inventory_label)
	inventory_changed.connect(_on_inventory_changed.bind(inventory_label))
	_on_inventory_changed(inventory_label)


func _update_coin_hud() -> void:
	if is_instance_valid(_coin_label):
		_coin_label.text = "PAPUCOIN: %d" % coins


func _on_inventory_changed(label: Label) -> void:
	if is_instance_valid(label):
		label.text = "PAPAMAX: %d (G)" % papamax_count


func _on_coins_changed(_total: int) -> void:
	_update_coin_hud()
