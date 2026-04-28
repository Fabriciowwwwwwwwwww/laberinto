extends Node2D 
@export var music_tracks: Array[AudioStream]

func _ready() -> void:
	MusicManager.play_playlist(music_tracks)
	await get_tree().process_frame

	# Buscar jugador en la escena
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		print("⚠️ No se encontró jugador en la escena")
		return

	var player = players[0]

	# Restaurar estado del jugador solo si hay posición guardada
	if GameStateLaberinto.player_position != Vector2.ZERO:
		GameStateLaberinto.restore_player(player)
	else:
		print("⚪ No hay posición guardada, el jugador se mantiene en la posición de Godot")

	# Restaurar objetos destruidos
	for obj_id in GameStateLaberinto.objetos_destruidos:
		var obj = get_node_or_null(obj_id)
		if obj:
			obj.queue_free()  # o desactivar colisión/sprite según necesites

	# Restaurar puertas forzadas
	for puerta_id in GameStateLaberinto.puertas_ganzua_forzadas.keys():
		var puerta = get_node_or_null(puerta_id)
		if puerta and "escena_ya_completada" in puerta:
			puerta.escena_ya_completada = true
			puerta.animated_sprite_2d.play("Abierto")
			if puerta.has_node("CollisionShape2D"):
				puerta.get_node("CollisionShape2D").disabled = true
			if puerta.has_node("ui_container"):
				puerta.get_node("ui_container").visible = false
			puerta.set_process(false)
