class_name Cinematica
extends Node2D

@export var dialogue: DialogueResource = preload("res://scenes/quests/story_quests/template_laberinto/0_template_intro_laberinto/template_intro_components_laberinto/template_intro_laberinto.dialogue")

@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
@export var npc_node_path: NodePath

# 🔥 NUEVO → controlar si cambia de escena o no
@export var usar_next_scene: bool = true

var jugador_ha_hablado := false

# ---------------------------------------------------
func _ready() -> void:
	var npc = get_node_or_null(npc_node_path)

	if npc and npc.has_signal("interaction_ended"):
		npc.connect("interaction_ended", Callable(self, "_on_npc_interaction_ended"))

	# 🔥 reproducir diálogo automáticamente
	await reproducir_dialogo()

	# 🔥 esperar interacción SOLO si hay NPC
	if npc:
		await _esperar_confirmacion_npc()

	# 🔥 SOLO cambia de escena si está activado
	if usar_next_scene and next_scene != "":
		if not is_inside_tree():
			return

		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)

# ---------------------------------------------------
# 🔥 FUNCIÓN REUTILIZABLE (CLAVE)
func reproducir_dialogo() -> void:
	if not dialogue:
		return

	MusicManager.fade_out(1.0)

	DialogueManager.show_dialogue_balloon(dialogue, "", [self])

	await DialogueManager.dialogue_ended

	MusicManager.fade_in(1.0)

# ---------------------------------------------------
func _on_npc_interaction_ended() -> void:
	jugador_ha_hablado = true

# ---------------------------------------------------
func _esperar_confirmacion_npc() -> void:
	while not jugador_ha_hablado:
		if not is_inside_tree():
			return
		await get_tree().create_timer(0.01).timeout
