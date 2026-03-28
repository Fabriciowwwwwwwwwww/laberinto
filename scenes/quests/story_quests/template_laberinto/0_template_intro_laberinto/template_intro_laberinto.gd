extends Node2D 
@export var music_tracks: Array[AudioStream]

func _ready() -> void:
	MusicManager.play_playlist(music_tracks)
	await get_tree().process_frame
