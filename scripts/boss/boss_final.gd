extends Area2D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/personajes/proyectil_boss.tscn")

signal health_changed(current: int, maximum: int)
signal defeated

@export var max_health: int = 200
@export var contact_damage: int = 12
@export var damage_interval: float = 1.0
@export var projectile_damage: int = 12
@export var projectile_speed: float = 460.0
@export var projectile_interval: float = 1.8
@export var movement_range: float = 110.0
@export var movement_speed: float = 0.65
@export var hover_height: float = 14.0

@onready var sprite: Sprite2D = $Sprite

var health: int
var contact_player: Node2D
var target_player: Node2D
var damage_timer: float = 0.0
var projectile_timer: float = 1.0
var start_position: Vector2
var movement_time: float = 0.0


func _ready() -> void:
	health = max_health
	start_position = position
	add_to_group("boss")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	movement_time += delta
	var movement_offset := Vector2(
		sin(movement_time * movement_speed) * movement_range,
		sin(movement_time * movement_speed * 1.8) * hover_height
	)
	var movement_smoothing := 1.0 - exp(-delta * 3.0)
	position = position.lerp(start_position + movement_offset, movement_smoothing)
	sprite.rotation = sin(movement_time * movement_speed) * 0.025

	if is_instance_valid(contact_player):
		damage_timer -= delta
		if damage_timer <= 0.0:
			_damage_player()
			damage_timer = damage_interval

	if not is_instance_valid(target_player):
		return

	projectile_timer -= delta
	if projectile_timer <= 0.0:
		_shoot_projectile()
		projectile_timer = projectile_interval


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
		_damage_player()


func _on_body_exited(body: Node2D) -> void:
	if body == contact_player:
		contact_player = null


func _damage_player() -> void:
	if is_instance_valid(contact_player):
		contact_player.take_damage(contact_damage)


func _shoot_projectile() -> void:
	if not is_instance_valid(target_player):
		return

	var projectile := PROJECTILE_SCENE.instantiate() as Area2D
	var direction := (target_player.global_position - global_position).normalized()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + direction * 70.0
	projectile.call("setup", direction, projectile_speed, projectile_damage)
