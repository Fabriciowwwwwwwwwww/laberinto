extends Node2D

@export var music_tracks: Array[AudioStream]

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.zoom = Vector2(1, 1)  # 🔥 ZOOM

	MusicManager.play_playlist(music_tracks)

	await get_tree().process_frame
