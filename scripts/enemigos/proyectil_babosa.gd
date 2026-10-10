extends Area2D

@export var fall_acceleration: float = 520.0
@export var lifetime: float = 4.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 14


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(flight_direction: Vector2, projectile_speed: float, hit_damage: int) -> void:
	velocity = flight_direction.normalized() * projectile_speed + Vector2(0.0, -145.0)
	damage = hit_damage


func _physics_process(delta: float) -> void:
	velocity.y += fall_acceleration * delta
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
