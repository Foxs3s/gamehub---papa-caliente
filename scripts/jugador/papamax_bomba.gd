extends Area2D

const DAMAGE_NUMBER = preload("res://scripts/ui/damage_number.gd")

@export var throw_speed: float = 360.0
@export var explosion_radius: float = 150.0
@export var fuse_duration: float = 2.2

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var thrower: Node2D
var velocity: Vector2 = Vector2.ZERO
var critical_chance: float = 0.0
var fuse_timer: float = 0.0
var spent: bool = false


func _ready() -> void:
	fuse_timer = fuse_duration
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func setup(direction: float, source: Node2D, crit_chance: float) -> void:
	thrower = source
	critical_chance = crit_chance
	velocity = Vector2(direction * throw_speed, -220.0)


func _physics_process(delta: float) -> void:
	if spent:
		return
	fuse_timer -= delta
	velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity")) * delta
	global_position += velocity * delta
	sprite.rotation += delta * 7.0
	if fuse_timer <= 0.0:
		_explode()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("boss"):
		_explode()


func _on_body_entered(body: Node2D) -> void:
	if body != thrower:
		_explode()


func _explode() -> void:
	if spent:
		return
	spent = true

	var critical := randf() < critical_chance
	var damage := randi_range(17, 19) if critical else 16
	var targets := get_tree().get_nodes_in_group("enemies")
	for boss in get_tree().get_nodes_in_group("boss"):
		if not targets.has(boss):
			targets.append(boss)
	for target in targets:
		if (
			is_instance_valid(target)
			and target.has_method("take_damage")
			and _distance_to_target_hitbox(target) <= explosion_radius
		):
			target.call("take_damage", damage, critical)
	DAMAGE_NUMBER.show(self, global_position, damage, Color("#ffad42"), critical)
	_show_explosion()
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	sprite.modulate = Color("#ffbd4a")
	var explosion_tween := create_tween()
	explosion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	explosion_tween.tween_property(sprite, "scale", sprite.scale * 1.35, 0.12)
	explosion_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.12)
	explosion_tween.tween_callback(queue_free)


func _distance_to_target_hitbox(target: Node2D) -> float:
	var shape_node := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return target.global_position.distance_to(global_position)

	if shape_node.shape is CircleShape2D:
		var circle := shape_node.shape as CircleShape2D
		var scale := shape_node.global_scale.abs()
		var radius := circle.radius * maxf(scale.x, scale.y)
		return maxf(shape_node.global_position.distance_to(global_position) - radius, 0.0)

	var local_point := shape_node.to_local(global_position)
	var bounds := shape_node.shape.get_rect()
	var nearest_point := Vector2(
		clampf(local_point.x, bounds.position.x, bounds.end.x),
		clampf(local_point.y, bounds.position.y, bounds.end.y)
	)
	return shape_node.to_global(nearest_point).distance_to(global_position)


func _show_explosion() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var effect := Node2D.new()
	effect.name = "PapamaxExplosion"
	scene_root.add_child(effect)
	effect.global_position = global_position
	effect.scale = Vector2(0.08, 0.08)

	var flash := Polygon2D.new()
	flash.polygon = _circle_points(1.0, 48)
	flash.color = Color("#ff8a3599")
	effect.add_child(flash)

	var ring := Line2D.new()
	ring.points = _circle_points(1.0, 48)
	ring.closed = true
	ring.width = 0.035
	ring.default_color = Color("#ffe28a")
	ring.antialiased = true
	effect.add_child(ring)

	var effect_tween := effect.create_tween()
	effect_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	effect_tween.tween_property(
		effect,
		"scale",
		Vector2.ONE * explosion_radius,
		0.3
	)
	effect_tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
	effect_tween.tween_callback(effect.queue_free)


func _circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
