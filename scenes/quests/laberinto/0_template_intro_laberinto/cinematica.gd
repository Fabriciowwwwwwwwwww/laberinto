class_name Cinematica
extends Node2D

@export var dialogue: DialogueResource
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
@export var usar_next_scene: bool = true

var npc = null

# ---------------------------------------------------
func _ready() -> void:

	# 🔥 BUSCAR NPC REAL EN ESCENA
	await get_tree().process_frame

	npc = get_tree().get_first_node_in_group("npc_dialogo")

	if npc == null:
		print("❌ NPC NO ENCONTRADO EN GRUPO")
		return

	print("✅ NPC REAL encontrado:", npc.name)

	# 🔥 CONECTAR SEÑAL
	if not npc.is_connected("interaction_ended", Callable(self, "_on_npc_interaction_ended")):
		npc.connect("interaction_ended", Callable(self, "_on_npc_interaction_ended"))
		print("✅ Señal conectada correctamente")

	# 🔥 DIÁLOGO INICIAL
	await reproducir_dialogo()

	print("🟢 Intro terminada, esperando NPC...")


# ---------------------------------------------------
func reproducir_dialogo() -> void:

	if not dialogue:
		return

	# 🔻 APAGAR MÚSICA
	MusicManager.fade_out(1.0)

	# 🔥 mostrar diálogo
	DialogueManager.show_dialogue_balloon(dialogue, "", [self])
	await DialogueManager.dialogue_ended

	# ❌ NO vuelvas a prender música aquí
	# MusicManager.fade_in(1.0)  ← ELIMINA ESTO


# ---------------------------------------------------
func _on_npc_interaction_ended() -> void:

	print("🔥 RECIBÍ LA SEÑAL DEL NPC")

	# 🔺 VOLVER MÚSICA
	MusicManager.fade_in(1.0)

	if usar_next_scene and next_scene != "":
		
		print("➡ TELETRANSPORTANDO A:", next_scene)

		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
