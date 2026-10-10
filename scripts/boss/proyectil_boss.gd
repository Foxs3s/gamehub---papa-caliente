extends Area2D

@export var speed: float = 460.0
@export var damage: int = 12
@export var lifetime: float = 5.0

@onready var sprite: Sprite2D = $Sprite

var direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(flight_direction: Vector2, projectile_speed: float, hit_damage: int) -> void:
	direction = flight_direction.normalized()
	speed = projectile_speed
	damage = hit_damage
	sprite.flip_h = direction.x > 0.0


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
