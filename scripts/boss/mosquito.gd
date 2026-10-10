extends Area2D

const LEFT_TEXTURE: Texture2D = preload("res://assets/boss_fight/mosquitoo2.png")
const RIGHT_TEXTURE: Texture2D = preload("res://assets/boss_fight/mosquitoo.png")
const DAMAGE_NUMBER = preload("res://scripts/ui/damage_number.gd")

signal health_changed(current: int, maximum: int)
signal defeated
signal flight_phase_changed(phase: String)

@export var max_health: int = 80
@export var follow_speed: float = 65.0
@export var contact_damage: int = 5
@export var damage_interval: float = 1.2
@export var flight_attack_interval: float = 4.0
@export var flight_warning_duration: float = 0.9
@export var flight_speed: float = 620.0
@export var flight_damage: int = 14
@export var flight_recovery_duration: float = 0.65

enum FlightPhase {
	FOLLOWING,
	WARNING,
	DIVING,
	RECOVERING,
}

@onready var sprite: Sprite2D = $Sprite

var health: int
var target_player: Node2D
var contact_player: Node2D
var damage_timer: float = 0.0
var movement_time: float = 0.0
var flight_phase: FlightPhase = FlightPhase.FOLLOWING
var flight_phase_timer: float
var flight_destination: Vector2
var flight_attack_hit: bool = false


func _ready() -> void:
	health = max_health
	flight_phase_timer = flight_attack_interval
	add_to_group("boss")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	movement_time += delta
	if is_instance_valid(target_player):
		var horizontal_offset := target_player.global_position.x - global_position.x
		if horizontal_offset < 0.0:
			sprite.texture = LEFT_TEXTURE
		elif horizontal_offset > 0.0:
			sprite.texture = RIGHT_TEXTURE

	_update_flight_attack(delta)
	if flight_phase == FlightPhase.FOLLOWING and is_instance_valid(target_player):
		global_position = global_position.move_toward(
			target_player.global_position,
			follow_speed * delta
		)

	if flight_phase == FlightPhase.WARNING:
		sprite.modulate = Color("#ff6464") if int(movement_time * 8.0) % 2 == 0 else Color.WHITE
	elif flight_phase != FlightPhase.DIVING:
		sprite.modulate = Color.WHITE

	sprite.rotation = sin(movement_time * 3.0) * (0.08 if flight_phase == FlightPhase.DIVING else 0.05)
	sprite.position.y = sin(movement_time * 4.0) * 6.0

	if is_instance_valid(contact_player):
		damage_timer -= delta
		if damage_timer <= 0.0:
			contact_player.take_damage(contact_damage)
			damage_timer = damage_interval


func _update_flight_attack(delta: float) -> void:
	if not is_instance_valid(target_player):
		return

	match flight_phase:
		FlightPhase.FOLLOWING:
			flight_phase_timer -= delta
			if flight_phase_timer <= 0.0:
				_begin_flight_warning()
		FlightPhase.WARNING:
			flight_phase_timer -= delta
			if flight_phase_timer <= 0.0:
				flight_phase = FlightPhase.DIVING
				flight_attack_hit = false
				flight_phase_changed.emit("diving")
		FlightPhase.DIVING:
			global_position = global_position.move_toward(flight_destination, flight_speed * delta)
			if (
				not flight_attack_hit
				and global_position.distance_to(target_player.global_position) <= 80.0
			):
				_damage_with_flight_attack(target_player)
			if global_position.distance_to(flight_destination) <= 12.0:
				flight_phase = FlightPhase.RECOVERING
				flight_phase_timer = flight_recovery_duration
		FlightPhase.RECOVERING:
			flight_phase_timer -= delta
			if flight_phase_timer <= 0.0:
				flight_phase = FlightPhase.FOLLOWING
				flight_phase_timer = flight_attack_interval
				flight_phase_changed.emit("following")


func _begin_flight_warning() -> void:
	flight_phase = FlightPhase.WARNING
	flight_phase_timer = flight_warning_duration
	flight_attack_hit = false
	var arena_width := get_viewport_rect().size.x
	flight_destination = target_player.global_position + Vector2(0.0, -25.0)
	flight_destination.x = clampf(flight_destination.x, 70.0, arena_width - 70.0)
	flight_destination.y = maxf(flight_destination.y, 80.0)
	flight_phase_changed.emit("warning")


func _damage_with_flight_attack(body: Node2D) -> void:
	if flight_attack_hit or not body.has_method("take_damage"):
		return

	flight_attack_hit = true
	body.take_damage(flight_damage)


func set_target(player: Node2D) -> void:
	target_player = player


func is_within_attack_range(
	attacker_position: Vector2,
	attack_direction: float,
	horizontal_range: float,
	vertical_range: float
) -> bool:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var target_position := global_position
	var half_size := Vector2.ZERO
	if collision_shape != null:
		target_position = collision_shape.global_position
		if collision_shape.shape is RectangleShape2D:
			var rectangle := collision_shape.shape as RectangleShape2D
			half_size = rectangle.size * collision_shape.global_scale.abs() * 0.5

	var offset := target_position - attacker_position
	if absf(offset.x) > half_size.x and offset.x * attack_direction < 0.0:
		return false

	var distance_to_hitbox := Vector2(
		maxf(absf(offset.x) - half_size.x, 0.0),
		maxf(absf(offset.y) - half_size.y, 0.0)
	)
	return (
		distance_to_hitbox.length() <= horizontal_range
		and distance_to_hitbox.y <= vertical_range
	)


func take_damage(amount: int, is_critical: bool = false) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	DAMAGE_NUMBER.show(self, global_position, amount, Color("#fff176"), is_critical)
	sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	var hit_tween := create_tween()
	hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.22)

	if health == 0:
		monitoring = false
		sprite.hide()
		defeated.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		contact_player = body
		damage_timer = damage_interval
		if flight_phase == FlightPhase.DIVING:
			_damage_with_flight_attack(body)
		else:
			body.take_damage(contact_damage)
		_stun_player_if_stomped(body)


func _on_body_exited(body: Node2D) -> void:
	if body == contact_player:
		contact_player = null


func _stun_player_if_stomped(body: Node2D) -> void:
	if (
		body.has_method("is_stomping_enemy")
		and body.call("is_stomping_enemy", self)
		and body.has_method("apply_stun")
	):
		body.call("apply_stun")
