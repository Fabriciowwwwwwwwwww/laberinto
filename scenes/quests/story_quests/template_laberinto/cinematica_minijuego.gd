class_name CinematicaEvento
extends Node2D

@export var id_cinematica: String = "intro_unica"

@export var dialogue: DialogueResource

@export var npc_node_path: NodePath

@export var reproducir_una_vez: bool = true

var jugador_ha_hablado := false

# ---------------------------------------------------
func _ready():

	# 🔥 SI YA SE EJECUTÓ → NO HACER NADA
	if reproducir_una_vez and Gamestateminijuegos.cinematicas_vistas.has(id_cinematica):
		queue_free()
		return

	var npc = get_node_or_null(npc_node_path)

	if npc and npc.has_signal("interaction_ended"):
		npc.connect("interaction_ended", Callable(self, "_on_npc_interaction_ended"))

	await reproducir_dialogo()

	if npc:
		await _esperar_confirmacion_npc()

	# 🔥 MARCAR COMO VISTA
	if reproducir_una_vez:
		Gamestateminijuegos.cinematicas_vistas[id_cinematica] = true

	print("✅ Cinemática completada:", id_cinematica)

# ---------------------------------------------------
func reproducir_dialogo():
	if not dialogue:
		return

	MusicManager.fade_out(1.0)

	DialogueManager.show_dialogue_balloon(dialogue, "", [self])

	await DialogueManager.dialogue_ended

	MusicManager.fade_in(1.0)

# ---------------------------------------------------
func _on_npc_interaction_ended():
	jugador_ha_hablado = true

# ---------------------------------------------------
func _esperar_confirmacion_npc():
	while not jugador_ha_hablado:
		if not is_inside_tree():
			return
		await get_tree().create_timer(0.01).timeout
