extends CharacterBody2D

const PUNCH_TEXTURE: Texture2D = preload("res://assets/personajes/jugador/punch_02.png")
const ALTERNATE_PUNCH_TEXTURE: Texture2D = preload("res://assets/personajes/jugador/puño (1).png")

@export var velocityN: float = 250.0
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_range: float = 170.0
@export var attack_vertical_range: float = 110.0
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

signal health_changed(current: int, maximum: int)
signal defeated


func _ready() -> void:
	health = max_health
	checkpoint_position = global_position
	sprite_base_position = sprite.position
	sprite_base_scale = sprite.scale


func _process(delta: float) -> void:
	animation_time += delta
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
	if health > 0 and not is_attacking:
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

	if key_event.keycode == KEY_F:
		start_punch()
	elif jump_key_pressed:
		if is_on_floor() and health > 0:
			velocity.y = -jump_speed
			jump_button_held = true
			jump_hold_time = 0.0


func start_punch() -> void:
	if is_attacking or health <= 0:
		return

	is_attacking = true
	velocity.x = 0.0
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
	var boss := get_tree().get_first_node_in_group("boss")
	if (
		boss == null
		or not boss.has_method("take_damage")
		or not boss.has_method("is_within_attack_range")
	):
		return

	if not boss.call(
		"is_within_attack_range",
		global_position,
		facing_direction,
		attack_range,
		attack_vertical_range
	):
		return

	boss.call("take_damage", attack_damage)


func restore_full_health() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	if sprite != null:
		sprite.modulate = Color.WHITE


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if sprite != null:
		sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
		var hit_tween := create_tween()
		hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.22)
	if health == 0:
		velocity = Vector2.ZERO
		defeated.emit()
