class_name Cinematica
extends Node2D

@export var dialogue: DialogueResource = preload("res://scenes/quests/story_quests/template_laberinto/0_template_intro_laberinto/template_intro_components_laberinto/template_intro_laberinto.dialogue")  # Diálogo introductorio
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
@export var npc_node_path: NodePath

var jugador_ha_hablado := false

func _ready() -> void:
	print("📌 npc_node_path:", npc_node_path)
	var npc = get_node_or_null(npc_node_path)

	if npc:
		print("✅ NPC encontrado:", npc.name)
		if npc.has_signal("interaction_ended"):
			print("✅ NPC tiene señal 'interaction_ended'")
			npc.connect("interaction_ended", Callable(self, "_on_npc_interaction_ended"))
		else:
			print("❌ El nodo NPC no tiene la señal 'interaction_ended'")
	else:
		print("❌ No se encontró el NPC con esa ruta")

	# 🔸 Mostrar diálogo introductorio automático
	if dialogue:
		print("💬 Mostrando diálogo inicial...")
		DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended
		print("✅ Diálogo inicial terminado")

	# ❗ Esperar a que el jugador HABLE MANUALMENTE con el NPC
	await _esperar_confirmacion_npc()

	# 🔁 Cambiar de escena después de la interacción
	if next_scene:
		print("🎬 Cambiando a la escena:", next_scene)
		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)

func _on_npc_interaction_ended() -> void:
	print("🟣 [Cinematica] ¡El jugador habló con el NPC!")
	jugador_ha_hablado = true

func _esperar_confirmacion_npc() -> void:
	print("🧩 Esperando a que el jugador hable con el NPC...")
	while not jugador_ha_hablado:
		await get_tree().process_frame
	print("✅ Confirmación recibida. Continuando.")
