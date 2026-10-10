extends Area2D

const LEFT_TEXTURE: Texture2D = preload("res://assets/boss_fight/mosquitoo2.png")
const RIGHT_TEXTURE: Texture2D = preload("res://assets/boss_fight/mosquitoo.png")

signal health_changed(current: int, maximum: int)
signal defeated

@export var max_health: int = 80
@export var follow_speed: float = 65.0
@export var contact_damage: int = 6
@export var damage_interval: float = 1.2

@onready var sprite: Sprite2D = $Sprite

var health: int
var target_player: Node2D
var contact_player: Node2D
var damage_timer: float = 0.0
var movement_time: float = 0.0


func _ready() -> void:
	health = max_health
	add_to_group("boss")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	if is_instance_valid(target_player):
		var horizontal_offset := target_player.global_position.x - global_position.x
		if horizontal_offset < 0.0:
			sprite.texture = LEFT_TEXTURE
		elif horizontal_offset > 0.0:
			sprite.texture = RIGHT_TEXTURE

		global_position = global_position.move_toward(
			target_player.global_position,
			follow_speed * delta
		)

	movement_time += delta
	sprite.rotation = sin(movement_time * 3.0) * 0.05
	sprite.position.y = sin(movement_time * 4.0) * 6.0

	if is_instance_valid(contact_player):
		damage_timer -= delta
		if damage_timer <= 0.0:
			contact_player.take_damage(contact_damage)
			damage_timer = damage_interval


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


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
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
		body.take_damage(contact_damage)


func _on_body_exited(body: Node2D) -> void:
	if body == contact_player:
		contact_player = null
