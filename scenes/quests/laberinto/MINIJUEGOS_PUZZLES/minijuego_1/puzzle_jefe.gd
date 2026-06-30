extends Node2D

@export var dialogue_ganar: DialogueResource
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String

var detecto_golem := false
var cambiando := false

func _process(_delta):
	if cambiando:
		return

	var golems = get_tree().get_nodes_in_group("golem")

	if !detecto_golem and golems.size() > 0:
		detecto_golem = true

	if detecto_golem and golems.is_empty():
		cambiando = true
		await ganar()

func ganar():
	Gamestateminijuegos.changing_scene = true

	if dialogue_ganar:
		MusicManager.fade_out(1.0)
		await DialogueManager.show_dialogue_balloon(dialogue_ganar)
		await DialogueManager.dialogue_ended
		MusicManager.fade_in(1.0)

	SceneSwitcher2.change_to_file_with_transition(next_scene, spawn_point_path)
