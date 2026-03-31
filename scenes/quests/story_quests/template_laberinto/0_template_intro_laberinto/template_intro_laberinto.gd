extends Node2D 
@export var music_tracks: Array[AudioStream]

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	#player.get camrara zoom is 0.5
	MusicManager.play_playlist(music_tracks)
	await get_tree().process_frame
