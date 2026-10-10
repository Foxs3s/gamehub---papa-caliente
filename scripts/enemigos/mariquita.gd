extends Area2D

const LEFT_TEXTURE: Texture2D = preload("res://assets/boss_fight/mariquitaizquierda.png")
const RIGHT_TEXTURE: Texture2D = preload("res://assets/boss_fight/mariquitaderecha.png")
const DAMAGE_NUMBER = preload("res://scripts/ui/damage_number.gd")
const COIN_SCENE: PackedScene = preload("res://scenes/objetos/moneda.tscn")

signal defeated

@export var max_health: int = 30
@export var follow_speed: float = 95.0
@export var contact_damage: int = 6
@export var damage_interval: float = 0.9
@export var attack_range: float = 75.0
@export var attack_vertical_range: float = 70.0
@export var coin_reward: int = 1

@onready var sprite: Sprite2D = $Sprite

var health: int
var target_player: Node2D
var contact_player: Node2D
var damage_timer: float = 0.0
var movement_time: float = 0.0
var alive: bool = true


func _ready() -> void:
	health = max_health
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.z_index = 5
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if not alive:
		return

	movement_time += delta
	if is_instance_valid(target_player):
		var horizontal_offset := target_player.global_position.x - global_position.x
		if horizontal_offset < 0.0:
			sprite.texture = LEFT_TEXTURE
		elif horizontal_offset > 0.0:
			sprite.texture = RIGHT_TEXTURE

		var distance := global_position.distance_to(target_player.global_position)
		if distance > attack_range * 0.7:
			global_position = global_position.move_toward(
				target_player.global_position,
				follow_speed * delta
			)

	sprite.position.y = sin(movement_time * 5.0) * 3.0
	sprite.rotation = sin(movement_time * 3.0) * 0.035

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


func take_damage(amount: int, is_critical: bool = false) -> void:
	if amount <= 0 or not alive:
		return

	health = maxi(health - amount, 0)
	DAMAGE_NUMBER.show(self, global_position, amount, Color("#fff176"), is_critical)
	sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	var hit_tween := create_tween()
	hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.22)

	if health == 0:
		alive = false
		monitoring = false
		sprite.hide()
		_drop_coins()
		defeated.emit()


func _on_body_entered(body: Node2D) -> void:
	if not alive or not body.has_method("take_damage"):
		return

	contact_player = body
	damage_timer = damage_interval
	contact_player.take_damage(contact_damage)
	if (
		contact_player.has_method("is_stomping_enemy")
		and contact_player.call("is_stomping_enemy", self)
		and contact_player.has_method("apply_stun")
	):
		contact_player.call("apply_stun")


func _on_body_exited(body: Node2D) -> void:
	if body == contact_player:
		contact_player = null


func _drop_coins() -> void:
	var coin := COIN_SCENE.instantiate() as Area2D
	get_tree().current_scene.add_child(coin)
	coin.global_position = global_position
	coin.set("value", coin_reward)
