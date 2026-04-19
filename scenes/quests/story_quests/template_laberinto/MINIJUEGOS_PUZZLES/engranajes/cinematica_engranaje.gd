extends Node2D
class_name cinematica_engranaje

signal cinematica_terminada

@export var dialogue: DialogueResource
@export var perder_dialogue: DialogueResource
@export var tiempo_dialogue: DialogueResource
@export var ganar_dialogue: DialogueResource

@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String

var solucion_texto: String = ""
var solucion_actual: Array = []

var tipo_perdida := ""
var ha_ganado := false

# -------------------------
# RECIBIR SOLUCIÓN
# -------------------------
func set_solucion(sol: Array) -> void:
	solucion_actual = sol.duplicate()
	solucion_texto = get_solucion_texto()

	print("📥 SOLUCIÓN ACTUALIZADA:\n" + solucion_texto)

# -------------------------
# FORMATEAR TEXTO
# -------------------------
func get_solucion_texto() -> String:
	var texto := ""

	for i in range(solucion_actual.size()):
		texto += "Engranaje %d → %s\n" % [
			i + 1,
			"Derecha" if solucion_actual[i] == 0 else "Izquierda"
		]

	return texto

# -------------------------
# READY (INTRO INICIAL)
# -------------------------
func _ready() -> void:
	add_to_group("cinematica")
	await reproducir_intro()

# -------------------------
# INTRO
# -------------------------
func reproducir_intro() -> void:
	await get_tree().process_frame

	print("🎬 Intro iniciando...")

	await reproducir_dialogo_con_musica(dialogue)

	print("✅ Intro terminada")
	cinematica_terminada.emit()

# -------------------------
# PERDER (ERROR / TIEMPO)
# -------------------------
func notificar_perdida(tipo := "error") -> void:

	tipo_perdida = tipo

	var dialogo: DialogueResource = null

	if tipo_perdida == "tiempo":
		dialogo = tiempo_dialogue
	else:
		dialogo = perder_dialogue

	await reproducir_dialogo_con_musica(dialogo)

	cinematica_terminada.emit()

# -------------------------
# GANAR
# -------------------------
func notificar_ganador() -> void:

	ha_ganado = true

	await reproducir_dialogo_con_musica(ganar_dialogue)

	_on_cambio_de_escena()
	cinematica_terminada.emit()

	cinematica_terminada.emit()
func _on_cambio_de_escena() -> void:
	if next_scene != "":
		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
func notificar_progreso(actual: int, total: int) -> void:

	print("Progreso:", actual, "/", total)

	await reproducir_dialogo_con_musica(ganar_dialogue)

	cinematica_terminada.emit()

	cinematica_terminada.emit()
func reproducir_dialogo_con_musica(dialogo: DialogueResource) -> void:

	if not dialogo:
		return

	# 🔻 apagar música
	MusicManager.fade_out(1.0)

	await DialogueManager.show_dialogue_balloon(
		dialogo,
		"",
		[self]
	)

	await DialogueManager.dialogue_ended

	# 🔺 volver música
	MusicManager.fade_in(1.0)
