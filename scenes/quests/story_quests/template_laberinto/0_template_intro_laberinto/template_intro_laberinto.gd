extends Node2D

@export var music_tracks: Array[AudioStream]

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	
	# --- CONFIGURACIÓN DE CÁMARA Y ESTADO INICIAL ---
	if player:
		# 1. Configurar la cámara del jugador
		var cam_player = player.get_node_or_null("Camera2D")
		if cam_player:
			cam_player.enabled = false # Apagamos la del jugador
			cam_player.zoom = Vector2(2.1, 2.1) # Zoom deseado
		
		# 2. Asegurarnos que la cámara de la Intro sea la principal
		var cam_intro = $Camera2D # Asumiendo que Camera2D es hijo de Intro
		if cam_intro:
			cam_intro.make_current()

		# 3. Ocultar equipo de combate
		var arma = player.get_node_or_null("arma")
		if arma: arma.visible = false
		
		var luz = player.get_node_or_null("PointLight2D")
		if luz: luz.visible = false

	# --- MÚSICA ---
	MusicManager.play_playlist(music_tracks)

	await get_tree().process_frame
