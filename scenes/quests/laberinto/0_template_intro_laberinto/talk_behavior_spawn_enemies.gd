@tool
class_name TalkBehaviorDialogueOnly
extends Node

signal npc_finished_dialogue(npc)

@export var persona: CharacterBody2D
@export var dialogue: DialogueResource
@export var title: String = ""

@onready var interact_area: InteractArea = $"../interact_area"

var puede_interactuar := true


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if interact_area == null:
		push_error("❌ No se encontró InteractArea")
		return

	if not interact_area.interaction_started.is_connected(_on_interaction_started):
		interact_area.interaction_started.connect(_on_interaction_started)


func _on_interaction_started(player, from_right: bool) -> void:
	if not puede_interactuar:
		interact_area.end_interaction()
		return

	puede_interactuar = false

	interact_area.monitoring = false
	interact_area.monitorable = false

	DialogueManager.show_dialogue_balloon(
		dialogue,
		title,
		[get_parent(), player, {}]
	)

	# Esperar a que termine TODO el diálogo
	await DialogueManager.dialogue_ended

	# Esperar un frame extra
	await get_tree().process_frame

	print("💬 NPC terminó completamente el diálogo")

	npc_finished_dialogue.emit(get_parent())

	interact_area.end_interaction()
