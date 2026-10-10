extends CharacterBody2D

@export var velocityN: float = 250.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var isAttacking: bool = false


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
	if isAttacking:
		return

	var direction := Vector2.ZERO

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
		_play_animation(&"walk") #A syntax issue that prevented the code from working properly has been fixed

		if direction.x < 0:
			animated_sprite.flip_h = true
		elif direction.x > 0:
			animated_sprite.flip_h = false
	else:
		_play_animation(&"stay")

	if Input.is_key_pressed(KEY_F):
		start_punch()


func start_punch() -> void:
	if not animated_sprite.sprite_frames.has_animation(&"punch"):
		return

	isAttacking = true
	velocity = Vector2.ZERO

	animated_sprite.play(&"punch") 


func _on_animation_finished() -> void:
	if animated_sprite.animation == &"punch":
		isAttacking = false


func _play_animation(animation_name: StringName) -> void:
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	elif animated_sprite.sprite_frames.has_animation(&"default"):
		animated_sprite.play(&"default")
