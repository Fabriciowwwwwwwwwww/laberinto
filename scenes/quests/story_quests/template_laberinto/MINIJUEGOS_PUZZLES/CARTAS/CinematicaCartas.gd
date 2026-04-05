extends Node2D
class_name CinematicaCartas

signal cinematica_terminada
@export var progreso_dialogue: DialogueResource  # 👈 NUEVO
# 🎬 DIALOGOS
@export var dialogue: DialogueResource
@export var perder_dialogue: DialogueResource
@export var tiempo_dialogue: DialogueResource
@export var ganar_dialogue: DialogueResource
@export var previo_final_dialogue: DialogueResource
@export var final_dialogue: DialogueResource

# 🌍 ESCENA
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String

# 🧠 DATOS
var solucion_actual: Array = []
var tipo_operacion: String = ""
var objetivo: int = 0

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	add_to_group("cinematica")
	await reproducir_intro()

# -------------------------
# INTRO
# -------------------------
func reproducir_intro() -> void:
	await get_tree().process_frame

	print("🎬 Cinemática Cartas: INICIO")

	if dialogue:
		print("📢 MOSTRANDO DIALOGO INTRO")

		var balloon = DialogueManager.show_dialogue_balloon(
			dialogue, "", [self]
		)

		if balloon:
			await DialogueManager.dialogue_ended

	print("✅ Cinemática Cartas: FIN INTRO")
	cinematica_terminada.emit()

# -------------------------
# PREVIO FINAL
# -------------------------
func notificar_previo_final() -> void:
	if previo_final_dialogue:
		print("📢 MOSTRANDO DIALOGO PREVIO FINAL")

		var balloon = DialogueManager.show_dialogue_balloon(
			previo_final_dialogue, "", [self]
		)

		if balloon:
			await DialogueManager.dialogue_ended

	cinematica_terminada.emit()

# -------------------------
# FINAL GANADO
# -------------------------
func notificar_final_ganado() -> void:
	if final_dialogue:
		print("📢 MOSTRANDO DIALOGO FINAL GANADO")

		var balloon = DialogueManager.show_dialogue_balloon(
			final_dialogue, "", [self]
		)

		if balloon:
			await DialogueManager.dialogue_ended

	# 🔥 cambio de escena SOLO aquí
	_on_cambio_de_escena()

	cinematica_terminada.emit()

# -------------------------
# SET SOLUCION
# -------------------------
func set_solucion(sol: Array, tipo: String, valor_objetivo: int) -> void:
	solucion_actual = sol.duplicate()
	tipo_operacion = tipo
	objetivo = valor_objetivo

	print("📥 Cinemática recibe solución:", solucion_actual, "Tipo:", tipo_operacion, "Objetivo:", objetivo)

# -------------------------
# PERDER
# -------------------------
func notificar_perdida(tipo := "error") -> void:
	var dialogo: DialogueResource = null

	if tipo == "tiempo":
		dialogo = tiempo_dialogue
	else:
		dialogo = perder_dialogue

	if dialogo:
		print("📢 MOSTRANDO DIALOGO PERDER")

		var balloon = DialogueManager.show_dialogue_balloon(dialogo, "", [self])
		if balloon:
			await DialogueManager.dialogue_ended

	cinematica_terminada.emit()

# -------------------------
# PROGRESO (GANAR RONDA)
# -------------------------
func notificar_progreso(actual: int, total: int) -> void:
	print("Progreso:", actual, "/", total)

	if progreso_dialogue:
		print("📢 MOSTRANDO DIALOGO PROGRESO")

		var balloon = DialogueManager.show_dialogue_balloon(
			progreso_dialogue, "", [self]
		)

		if balloon:
			await DialogueManager.dialogue_ended

	cinematica_terminada.emit()

# -------------------------
# CAMBIO ESCENA
# -------------------------
func _on_cambio_de_escena() -> void:
	if next_scene != "":
		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
