@tool
class_name TalkBehaviorSpawnEnemies
extends Node

@export var persona: CharacterBody2D
@export var dialogue: DialogueResource
@export var title: String = ""

@export var enemy_scene: PackedScene
@export var spawn_1: Node2D
@export var spawn_2: Node2D

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

	await DialogueManager.dialogue_ended

	spawnear_enemigos()

	interact_area.end_interaction()


func spawnear_enemigos() -> void:

	if enemy_scene == null:
		push_error("❌ Enemy Scene no asignado")
		return

	var e1 = enemy_scene.instantiate()
	var e2 = enemy_scene.instantiate()

	get_tree().current_scene.add_child(e1)
	get_tree().current_scene.add_child(e2)

	e1.global_position = spawn_1.global_position
	e2.global_position = spawn_2.global_position

	if persona:
		persona.queue_free()
