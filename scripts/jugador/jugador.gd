extends CharacterBody2D

const PUNCH_TEXTURE: Texture2D = preload("res://assets/personajes/jugador/punch_02.png")
const ALTERNATE_PUNCH_TEXTURE: Texture2D = preload("res://assets/personajes/jugador/puño (1).png")
const DAMAGE_NUMBER = preload("res://scripts/ui/damage_number.gd")
const PAPAMAX_SCENE: PackedScene = preload("res://scenes/objetos/papamax_bomba.tscn")
const BASE_MAX_HEALTH: int = 100
const BASE_CRITICAL_CHANCE: float = 0.2
const BASE_NORMAL_DAMAGE_MIN: int = 8
const BASE_NORMAL_DAMAGE_MAX: int = 10
const BASE_CRITICAL_DAMAGE_MIN: int = 11
const BASE_CRITICAL_DAMAGE_MAX: int = 15
const HEART_HEALTH_BONUS: int = 20
const SWORD_DAMAGE_BONUS: int = 4

@export var velocityN: float = 250.0
@export var max_health: int = 100
@export_range(0.0, 1.0) var critical_chance: float = 0.2
@export var normal_punch_damage_min: int = 8
@export var normal_punch_damage_max: int = 10
@export var critical_punch_damage_min: int = 11
@export var critical_punch_damage_max: int = 15
@export var stun_duration: float = 0.85
@export var attack_range: float = 80.0
@export var attack_vertical_range: float = 75.0
@export var jump_speed: float = 650.0
@export var jump_hold_acceleration: float = 800.0
@export var max_jump_hold_time: float = 0.34

@onready var sprite: Sprite2D = $Sprite
var is_attacking: bool = false
var health: int
var facing_direction: float = 1.0
var animation_time: float = 0.0
var sprite_base_position: Vector2
var sprite_base_scale: Vector2
var use_alternate_punch: bool = true
var jump_button_held: bool = false
var jump_hold_time: float = 0.0
var checkpoint_position: Vector2
var death_started: bool = false
var stun_time_remaining: float = 0.0

signal health_changed(current: int, maximum: int)
signal defeated


func _ready() -> void:
	health = max_health
	checkpoint_position = global_position
	sprite_base_position = sprite.position
	sprite_base_scale = sprite.scale


func _process(delta: float) -> void:
	animation_time += delta
	if stun_time_remaining > 0.0:
		stun_time_remaining = maxf(stun_time_remaining - delta, 0.0)
		if stun_time_remaining == 0.0 and health > 0:
			sprite.modulate = Color.WHITE

	if is_attacking:
		return

	var target_position := sprite_base_position
	var target_scale := sprite_base_scale
	if not is_on_floor():
		target_scale *= Vector2(0.94, 1.06)
		sprite.rotation = move_toward(sprite.rotation, deg_to_rad(-facing_direction * 5.0), delta * 5.0)
	elif absf(velocity.x) > 1.0:
		var hop_phase := fposmod(animation_time * 8.0, TAU)
		var hop_height := maxf(0.0, sin(hop_phase))
		var landing_squash := pow(maxf(0.0, -cos(hop_phase)), 8.0)
		target_position.y -= hop_height * 7.0
		target_scale *= Vector2(1.0 + hop_height * 0.035, 1.0 - hop_height * 0.025 - landing_squash * 0.04)
		sprite.rotation = move_toward(sprite.rotation, sin(hop_phase) * 0.025, delta * 10.0)
	else:
		target_position.y += sin(animation_time * 3.2) * 1.5
		target_scale *= Vector2(1.0 + sin(animation_time * 3.2) * 0.012, 1.0)
		sprite.rotation = move_toward(sprite.rotation, 0.0, delta * 8.0)

	var smoothing := 1.0 - exp(-delta * 14.0)
	sprite.position = sprite.position.lerp(target_position, smoothing)
	sprite.scale = sprite.scale.lerp(target_scale, smoothing)


func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	if not is_on_floor():
		if jump_button_held and velocity.y < 0.0 and jump_hold_time < max_jump_hold_time:
			var hold_delta: float = minf(delta, max_jump_hold_time - jump_hold_time)
			velocity.y -= jump_hold_acceleration * hold_delta
			jump_hold_time += hold_delta
		velocity.y += gravity * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0
		jump_button_held = false
		jump_hold_time = 0.0

	var direction := 0.0
	if health > 0 and stun_time_remaining <= 0.0:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0

		velocity.x = direction * velocityN
		if direction < 0.0:
			facing_direction = -1.0
			sprite.flip_h = true
		elif direction > 0.0:
			facing_direction = 1.0
			sprite.flip_h = false

	else:
		velocity.x = 0.0

	move_and_slide()
	if GameState.try_transition_at_stage_edge(self):
		return
	if global_position.y > get_viewport_rect().size.y + 160.0:
		_respawn_at_checkpoint()


func _respawn_at_checkpoint() -> void:
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	jump_button_held = false
	jump_hold_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	var jump_key_pressed := key_event.keycode == KEY_SPACE or key_event.keycode == KEY_W
	if not key_event.pressed:
		if jump_key_pressed:
			jump_button_held = false
		return
	if key_event.echo:
		return
	if stun_time_remaining > 0.0:
		return

	if key_event.keycode == KEY_F:
		start_punch()
	elif key_event.keycode == KEY_G:
		throw_papamax()
	elif jump_key_pressed:
		if is_on_floor() and health > 0:
			velocity.y = -jump_speed
			jump_button_held = true
			jump_hold_time = 0.0


func start_punch() -> void:
	if is_attacking or health <= 0 or stun_time_remaining > 0.0:
		return

	is_attacking = true
	sprite.texture = ALTERNATE_PUNCH_TEXTURE if use_alternate_punch else PUNCH_TEXTURE
	use_alternate_punch = not use_alternate_punch
	if sprite.texture == ALTERNATE_PUNCH_TEXTURE:
		var texture_tween := create_tween()
		texture_tween.tween_interval(0.18)
		texture_tween.tween_callback(func() -> void: sprite.texture = PUNCH_TEXTURE)

	var attack_tween := create_tween()
	attack_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	attack_tween.tween_property(
		sprite,
		"position",
		sprite_base_position + Vector2(facing_direction * 20.0, -2.0),
		0.1
	)
	attack_tween.parallel().tween_property(sprite, "scale", sprite_base_scale * Vector2(1.12, 0.94), 0.1)
	attack_tween.tween_callback(_deal_attack_damage)
	attack_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	attack_tween.tween_property(sprite, "position", sprite_base_position, 0.16)
	attack_tween.parallel().tween_property(sprite, "scale", sprite_base_scale, 0.16)
	attack_tween.tween_callback(func() -> void: is_attacking = false)


func _deal_attack_damage() -> void:
	if stun_time_remaining > 0.0 or health <= 0:
		return

	var targets := get_tree().get_nodes_in_group("boss")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not targets.has(enemy):
			targets.append(enemy)

	var target: Node2D
	var closest_distance := INF
	for candidate in targets:
		if (
			not is_instance_valid(candidate)
			or not candidate.has_method("take_damage")
			or not candidate.has_method("is_within_attack_range")
		):
			continue

		if not candidate.call(
			"is_within_attack_range",
			global_position,
			facing_direction,
			attack_range,
			attack_vertical_range
		):
			continue

		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < closest_distance:
			target = candidate
			closest_distance = distance

	if target == null:
		return

	var is_critical := randf() < critical_chance
	var damage: int
	if is_critical:
		damage = randi_range(critical_punch_damage_min, critical_punch_damage_max)
	else:
		damage = randi_range(normal_punch_damage_min, normal_punch_damage_max)
	target.call("take_damage", damage, is_critical)


func apply_shop_upgrades(
	heart_upgrades: int,
	sword_purchased: bool,
	heal_added_health: bool = false
) -> void:
	var previous_max_health := max_health
	max_health = BASE_MAX_HEALTH + HEART_HEALTH_BONUS * heart_upgrades
	normal_punch_damage_min = BASE_NORMAL_DAMAGE_MIN + (SWORD_DAMAGE_BONUS if sword_purchased else 0)
	normal_punch_damage_max = BASE_NORMAL_DAMAGE_MAX + (SWORD_DAMAGE_BONUS if sword_purchased else 0)
	critical_punch_damage_min = BASE_CRITICAL_DAMAGE_MIN + (SWORD_DAMAGE_BONUS if sword_purchased else 0)
	critical_punch_damage_max = BASE_CRITICAL_DAMAGE_MAX + (SWORD_DAMAGE_BONUS if sword_purchased else 0)
	critical_chance = 0.05 if sword_purchased else BASE_CRITICAL_CHANCE
	health = mini(health, max_health)
	if heal_added_health:
		var added_health := max_health - previous_max_health
		health = mini(health + added_health, max_health)
	health_changed.emit(health, max_health)


func throw_papamax() -> void:
	if health <= 0 or stun_time_remaining > 0.0 or GameState.papamax_count <= 0:
		return

	var bomb := PAPAMAX_SCENE.instantiate() as Area2D
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = global_position + Vector2(facing_direction * 42.0, -24.0)
	bomb.call("setup", facing_direction, self, critical_chance)
	GameState.papamax_count -= 1
	GameState.inventory_changed.emit()


func restore_full_health() -> void:
	health = max_health
	stun_time_remaining = 0.0
	health_changed.emit(health, max_health)
	if sprite != null:
		sprite.modulate = Color.WHITE


func apply_earthquake(source_position: Vector2, amount: int) -> void:
	if health <= 0 or not is_on_floor() or velocity.y < 0.0:
		return

	var knockback_direction := signf(global_position.x - source_position.x)
	if is_zero_approx(knockback_direction):
		knockback_direction = 1.0
	velocity = Vector2(knockback_direction * 320.0, -240.0)
	take_damage(amount)


func is_stomping_enemy(enemy: Node2D) -> bool:
	return velocity.y > 0.0 and global_position.y < enemy.global_position.y - 30.0


func apply_stun(duration: float = 0.0) -> void:
	if duration <= 0.0:
		duration = stun_duration
	if health <= 0 or duration <= 0.0:
		return

	stun_time_remaining = maxf(stun_time_remaining, duration)
	is_attacking = false
	jump_button_held = false
	velocity.x = 0.0
	sprite.modulate = Color("#b4a7ff")


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	DAMAGE_NUMBER.show(self, global_position, amount, Color("#ff6464"))
	if health == 0:
		explode()
		return

	if sprite != null:
		sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
		var hit_tween := create_tween()
		hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.22)


func explode() -> void:
	if death_started:
		return

	death_started = true
	if health > 0:
		health = 0
		health_changed.emit(health, max_health)
	velocity = Vector2.ZERO
	jump_button_held = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	set_process_unhandled_input(false)
	sprite.modulate = Color("#fff176")
	_create_explosion_fragments()

	var explosion_tween := create_tween()
	explosion_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	explosion_tween.tween_property(sprite, "scale", sprite_base_scale * 2.5, 0.55)
	explosion_tween.parallel().tween_property(
		sprite, "modulate", Color(1.0, 0.12, 0.0, 0.0), 0.55
	)
	explosion_tween.parallel().tween_property(sprite, "rotation", TAU, 0.55)
	explosion_tween.tween_callback(func() -> void:
		sprite.hide()
		defeated.emit()
	)


func _create_explosion_fragments() -> void:
	var colors := [Color("#fff176"), Color("#ff9800"), Color("#f44336")]
	for index in range(10):
		var angle := TAU * float(index) / 10.0 + randf_range(-0.15, 0.15)
		var direction := Vector2.RIGHT.rotated(angle)
		var fragment := Polygon2D.new()
		fragment.polygon = PackedVector2Array(
			[Vector2(0.0, -6.0), Vector2(5.0, 4.0), Vector2(-5.0, 4.0)]
		)
		fragment.position = sprite.position
		fragment.rotation = angle
		fragment.scale = Vector2.ONE * randf_range(0.8, 1.3)
		fragment.color = colors[index % colors.size()]
		add_child(fragment)

		var fragment_tween := create_tween()
		fragment_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fragment_tween.tween_property(
			fragment, "position", sprite.position + direction * randf_range(45.0, 110.0), 0.55
		)
		fragment_tween.parallel().tween_property(
			fragment,
			"modulate",
			Color(fragment.color.r, fragment.color.g, fragment.color.b, 0.0),
			0.55
		)
		fragment_tween.parallel().tween_property(
			fragment, "rotation", angle + randf_range(-TAU, TAU), 0.55
		)
		fragment_tween.tween_callback(fragment.queue_free)
