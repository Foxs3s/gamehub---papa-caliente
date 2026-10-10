extends Area2D

const SHOP_SCENE: PackedScene = preload("res://scenes/tienda/tienda.tscn")

@onready var prompt: Label = $Prompt

var nearby_player: CharacterBody2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or not is_instance_valid(nearby_player):
		return
	if event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_E:
		var ui_layer := CanvasLayer.new()
		ui_layer.layer = 30
		get_tree().current_scene.add_child(ui_layer)
		var shop := SHOP_SCENE.instantiate() as Control
		ui_layer.add_child(shop)
		shop.call("open_for_player", nearby_player)
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		nearby_player = body as CharacterBody2D
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body == nearby_player:
		nearby_player = null
		prompt.hide()
