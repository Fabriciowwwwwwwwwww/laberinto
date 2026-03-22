extends Node2D

# --------- ESCENAS ARRASTRABLES DESDE EL INSPECTOR ---------
@export var player_scene_path: String = "res://scenes/quests/story_quests/template_laberinto/1_template_stealth_laberinto/Player/player.tscn"
@onready var start_position: Marker2D = $StartPosition  # Nodo Position2D que indica donde aparecerá el jugador

func _ready():
	var scene = load(player_scene_path)
	if scene:
		var jugador = scene.instantiate()
		add_child(jugador)
		jugador.global_position = start_position.global_position
		print("Jugador instanciado")
		
		# --- Configurar la cámara del jugador ---
		var cam = jugador.get_node_or_null("Camera2D")
		if cam:
			cam.zoom = Vector2(1, 1)  # Zoom = 1 (tamaño normal)
			print("Cámara configurada con zoom 1")
		else:
			print("⚠️ No se encontró Camera2D en el jugador")
	else:
		print("⚠️ No se pudo cargar la escena del jugador")
