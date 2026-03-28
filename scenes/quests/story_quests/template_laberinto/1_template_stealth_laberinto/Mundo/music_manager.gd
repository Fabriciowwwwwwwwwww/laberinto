extends Node

var player := AudioStreamPlayer.new()
var tracks: Array[AudioStream] = []
var current_index := 0
var playing_special := false

func _ready():
	add_child(player)
	player.finished.connect(_on_music_finished)

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

func _on_music_finished():
	if playing_special:
		playing_special = false
		current_index = 0
	else:
		current_index = (current_index + 1) % tracks.size()
	
	_play_current()

func play_special(track: AudioStream):
	if not track:
		return
	
	playing_special = true
	player.stream = track
	player.play()
func fade_out(duration := 1.0):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -40, duration)

func fade_in(duration := 1.0):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", 0, duration)
