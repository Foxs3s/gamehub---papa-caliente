extends Node

const TRACKS: Dictionary = {
	"menu": "res://assets/audio/menu_inicio.ogg",
	"ambient": "res://assets/audio/niveles_normales.ogg",
	"first_boss": "res://assets/audio/boss_1.ogg",
	"second_boss": "res://assets/audio/boss_2.ogg",
	"final_boss": "res://assets/audio/boss_final.ogg",
	"store": "res://assets/audio/tienda.ogg",
}

var current_context: String = ""
var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.name = "AmbientMusicPlayer"
	_player.bus = "Master"
	_player.finished.connect(_replay_current_track)
	add_child(_player)


func set_stage_context(stage_id: String) -> void:
	match stage_id:
		"introduccion":
			set_context("first_boss")
		"mapa_1":
			set_context("second_boss")
		"boss_embestida":
			set_context("final_boss")
		_:
			set_context("ambient")


func set_context(context: String) -> void:
	if current_context == context and _player.stream != null and _player.playing:
		return
	if not TRACKS.has(context):
		push_error("Contexto musical desconocido: %s" % context)
		return

	current_context = context
	_player.stop()
	_player.stream = null
	var track_path: String = TRACKS[context]
	if not ResourceLoader.exists(track_path):
		return

	var track := ResourceLoader.load(track_path) as AudioStream
	if track == null:
		push_error("No se pudo cargar la pista de musica: %s" % track_path)
		return

	_player.stream = track
	_player.play()


func _replay_current_track() -> void:
	if current_context.is_empty() or not TRACKS.has(current_context):
		return
	if _player.stream != null:
		_player.play()
