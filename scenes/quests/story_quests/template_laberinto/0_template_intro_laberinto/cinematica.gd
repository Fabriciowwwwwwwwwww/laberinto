class_name Cinematica
extends Node2D

@export var dialogue: DialogueResource = preload("res://scenes/quests/story_quests/template_laberinto/0_template_intro_laberinto/template_intro_components_laberinto/template_intro_laberinto.dialogue")  # Diálogo introductorio
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
@export var npc_node_path: NodePath

var jugador_ha_hablado := false

func _ready() -> void:
	var npc = get_node_or_null(npc_node_path)
	if npc:
		if npc.has_signal("interaction_ended"):
			npc.connect("interaction_ended", Callable(self, "_on_npc_interaction_ended"))
	if dialogue:
		MusicManager.fade_out(1.0)  
		DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended
		MusicManager.fade_in(1.0)  
	await _esperar_confirmacion_npc()
	if next_scene:
		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
func _on_npc_interaction_ended() -> void:
	jugador_ha_hablado = true

func _esperar_confirmacion_npc() -> void:
	while not jugador_ha_hablado:
		await get_tree().process_frame
