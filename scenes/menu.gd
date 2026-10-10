extends Control

const GAME_SCENE_PATH: String = "res://logica/mapa_1.tscn"

@onready var play_button: Button = $JUGAR
@onready var exit_button: Button = $SALIR


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_play_pressed() -> void:
	var error: Error = get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if error != OK:
		push_error("No se pudo cargar la escena del juego: %s (Error: %s)" % [GAME_SCENE_PATH, error])


func _on_exit_pressed() -> void:
	get_tree().quit()
