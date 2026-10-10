extends Area2D

const DAMAGE_NUMBER = preload("res://scripts/ui/damage_number.gd")

const LEFT_TEXTURE: Texture2D = preload("res://assets/boss_fight/bossfinaalIzq.png")
const RIGHT_TEXTURE: Texture2D = preload("res://assets/boss_fight/bossfinaalDer.png")
const LEFT_SLIDE_TEXTURE: Texture2D = preload(
	"res://assets/boss_fight/bossfinaldeslizIzq (2).png"
)
const RIGHT_SLIDE_TEXTURE: Texture2D = preload(
	"res://assets/boss_fight/bossfinaalDereDesliz.png"
)
const SPRITE_SCALE: float = 0.38

signal health_changed(current: int, maximum: int)
signal phase_changed(phase: String)
signal charge_updated(time_left: float)
signal defeated

enum Phase {
	CHARGING,
	DASHING,
	STUNNED,
}

@export var max_health: int = 300
@export var charge_duration: float = 1.6
@export var charge_duration_max: float = 3.2
@export var dash_speed: float = 1080.0
@export var dash_duration: float = 1.4
@export var dash_damage: int = 28
@export var stun_duration: float = 1.35

@onready var sprite: Sprite2D = $Sprite
@onready var hitbox: CollisionShape2D = $CollisionShape2D

var health: int
var target_player: Node2D
var phase: Phase = Phase.CHARGING
var phase_timer: float
var charge_direction: float = -1.0
var movement_time: float = 0.0
var player_hit_this_dash: bool = false


func _ready() -> void:
	health = max_health
	phase_timer = _random_charge_duration()
	hitbox.disabled = true
	monitoring = false
	add_to_group("boss")
	body_entered.connect(_on_body_entered)
	_update_facing()
	phase_changed.emit("charging")
	charge_updated.emit(charge_duration)


func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	movement_time += delta
	if phase == Phase.CHARGING:
		phase_timer -= delta
		var charge_pulse := 1.0 + sin(movement_time * 12.0) * 0.07
		var charge_flash := 0.5 + sin(movement_time * 12.0) * 0.5
		sprite.modulate = Color(1.0, 0.18 + charge_flash * 0.42, 0.12, 1.0)
		sprite.scale = Vector2(
			SPRITE_SCALE * charge_pulse,
			SPRITE_SCALE / charge_pulse
		)
		charge_updated.emit(maxf(phase_timer, 0.0))
		if phase_timer <= 0.0:
			_begin_dash()
	elif phase == Phase.DASHING:
		var arena_width := get_viewport_rect().size.x
		var next_x := global_position.x + charge_direction * dash_speed * delta
		phase_timer -= delta
		if next_x < 80.0 or next_x > arena_width - 80.0:
			global_position.x = clampf(next_x, 80.0, arena_width - 80.0)
			_begin_stunned()
		else:
			global_position.x = next_x
		if phase == Phase.DASHING and phase_timer <= 0.0:
			_begin_charge()
	elif phase == Phase.STUNNED:
		phase_timer -= delta
		if phase_timer <= 0.0:
			_begin_charge()


func set_target(player: Node2D) -> void:
	target_player = player
	if phase == Phase.CHARGING:
		_update_facing()


func is_within_attack_range(
	attacker_position: Vector2,
	attack_direction: float,
	horizontal_range: float,
	vertical_range: float
) -> bool:
	if phase != Phase.CHARGING and phase != Phase.STUNNED:
		return false

	var half_size := Vector2.ZERO
	if hitbox.shape is RectangleShape2D:
		var rectangle := hitbox.shape as RectangleShape2D
		half_size = rectangle.size * hitbox.global_scale.abs() * 0.5

	var offset := hitbox.global_position - attacker_position
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
	if (
		amount <= 0
		or health <= 0
		or (phase != Phase.CHARGING and phase != Phase.STUNNED)
	):
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	DAMAGE_NUMBER.show(self, global_position, amount, Color("#fff176"), is_critical)
	sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	var hit_tween := create_tween()
	hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.22)

	if health == 0:
		monitoring = false
		hitbox.set_deferred("disabled", true)
		sprite.hide()
		defeated.emit()


func _begin_dash() -> void:
	phase = Phase.DASHING
	phase_timer = dash_duration
	player_hit_this_dash = false
	sprite.modulate = Color.WHITE
	sprite.texture = LEFT_SLIDE_TEXTURE if charge_direction < 0.0 else RIGHT_SLIDE_TEXTURE
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	monitoring = true
	hitbox.set_deferred("disabled", false)
	phase_changed.emit("dashing")


func _begin_charge() -> void:
	phase = Phase.CHARGING
	phase_timer = _random_charge_duration()
	monitoring = false
	hitbox.set_deferred("disabled", true)
	sprite.modulate = Color.WHITE
	_update_facing()
	phase_changed.emit("charging")
	charge_updated.emit(charge_duration)


func _begin_stunned() -> void:
	phase = Phase.STUNNED
	phase_timer = stun_duration
	monitoring = false
	hitbox.set_deferred("disabled", true)
	sprite.texture = LEFT_TEXTURE if charge_direction < 0.0 else RIGHT_TEXTURE
	sprite.modulate = Color("#aaaaff")
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	phase_changed.emit("stunned")


func _random_charge_duration() -> float:
	return randf_range(charge_duration, maxf(charge_duration, charge_duration_max))


func _update_facing() -> void:
	if not is_instance_valid(target_player):
		return

	var horizontal_offset := target_player.global_position.x - global_position.x
	if horizontal_offset != 0.0:
		charge_direction = signf(horizontal_offset)
		sprite.texture = LEFT_TEXTURE if charge_direction < 0.0 else RIGHT_TEXTURE


func _on_body_entered(body: Node2D) -> void:
	if phase != Phase.DASHING or player_hit_this_dash or not body.has_method("take_damage"):
		return

	player_hit_this_dash = true
	body.take_damage(dash_damage)
	if (
		body.has_method("is_stomping_enemy")
		and body.call("is_stomping_enemy", self)
		and body.has_method("apply_stun")
	):
		body.call("apply_stun")
	_begin_stunned()
