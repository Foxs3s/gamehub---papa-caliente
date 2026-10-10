extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

extends CharacterBody2D

@export var velocityN: float = 250.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var isAttacking: bool = false

func_ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)


func_physics_process(delta: float) -> void:
	if isAttacking:
		return

	var direction = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0

	direction = direction.normalized()

	velocity = direction * velocityN

	move_and_slide()

	if direction != Vector2.ZERO:
		animated_sprite.play("walk")

		if direction.x < 0:
			animated_sprite.flip_h = true
		elif direction.x > 0:
			animated_sprite.flip_h = false
	else:
			animated_sprite.play("stay")

	if Input.is_key_pressed(KEY_F):
		start_punch()

func start_punch() -> void:
	isAttacking = true
	velocity = Vector2.ZERO

	animated_sprite.play("punch")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "punch"
		isAttacking = false