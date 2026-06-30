class_name Cinematica
extends Node2D

@export var dialogue: DialogueResource
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
@export var usar_next_scene := true

var npc: Node
var talk: Node


func _ready() -> void:
	await get_tree().process_frame

	npc = get_tree().get_first_node_in_group("npc_dialogo")

	if npc == null:
		push_error("❌ No se encontró el NPC")
		return

	# Buscar automáticamente el hijo que tenga la señal
	talk = _buscar_talk(npc)

	if talk == null:
		push_error("❌ No se encontró TalkBehaviorDialogueOnly")
		return

	if not talk.npc_finished_dialogue.is_connected(_on_npc_finished):
		talk.npc_finished_dialogue.connect(_on_npc_finished)

	await reproducir_dialogo()

	print("🟢 Cinemática lista")


func _buscar_talk(node: Node) -> Node:
	if node.has_signal("npc_finished_dialogue"):
		return node

	for child in node.get_children():
		var encontrado := _buscar_talk(child)
		if encontrado != null:
			return encontrado

	return null


func reproducir_dialogo() -> void:
	if dialogue == null:
		return

	MusicManager.fade_out(1.0)

	DialogueManager.show_dialogue_balloon(
		dialogue,
		"",
		[self]
	)

	await DialogueManager.dialogue_ended


func _on_npc_finished(_npc) -> void:
	print("✅ Diálogo terminado completamente")

	await get_tree().process_frame
	await get_tree().process_frame

	MusicManager.fade_in(1.0)

	if usar_next_scene and next_scene != "":
		print("➡ Cambiando de escena:", next_scene)

		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
