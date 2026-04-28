extends Node

var player: AudioStreamPlayer
var tracks: Array[AudioStream] = []
var current_index := 0
var playing_special := false

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)

	player.bus = "Music"
	player.volume_db = 0

	# 🔥 FORZAR volumen del bus al iniciar
	var bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_index, AudioServer.get_bus_volume_db(bus_index))

	if not player.finished.is_connected(_on_music_finished):
		player.finished.connect(_on_music_finished)

# -------------------------
# PLAYLIST
# -------------------------
func play_playlist(new_tracks: Array[AudioStream]):
	if new_tracks.is_empty():
		return
	
	tracks = new_tracks
	current_index = 0
	playing_special = false
	
	_play_current()

func _play_current():
	if tracks.is_empty():
		return
	
	player.stream = tracks[current_index]
	player.play()

# -------------------------
# LOOP
# -------------------------
func _on_music_finished():
	if playing_special:
		playing_special = false
		current_index = 0
	else:
		current_index = (current_index + 1) % tracks.size()
	
	_play_current()

# -------------------------
# SPECIAL
# -------------------------
func play_special(track: AudioStream):
	if not track:
		return
	
	playing_special = true
	player.stream = track
	player.play()

# -------------------------
# FADE
# -------------------------
func fade_out(duration := 1.0):
	var tween = get_tree().create_tween()  # 🔥 más seguro
	tween.tween_property(player, "volume_db", -40, duration)

func fade_in(duration := 1.0):
	var tween = get_tree().create_tween()  # 🔥 más seguro
	tween.tween_property(player, "volume_db", 0, duration)
