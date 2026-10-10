extends Area2D

@export var value: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return

	GameState.add_coins(value)
	queue_free()
