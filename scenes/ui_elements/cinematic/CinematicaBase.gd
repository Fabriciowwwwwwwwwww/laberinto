extends Node2D
class_name CinematicaBase

signal cinematica_terminada

@export var id_cinematica: String = "evento_unico"
@export var reproducir_una_vez: bool = true

@export var dialogue_intro: DialogueResource
@export var dialogue_ganar: DialogueResource
@export var dialogue_perder: DialogueResource
@export var dialogue_tiempo: DialogueResource
@export var usar_next_scene: bool = true  # <--- ESTA ES LA LÍNEA QUE FALTA
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String

func _ready() -> void:
	add_to_group("cinematica")
	
	# Persistencia: Si ya se vio y es de un solo uso, saltar o borrar
	if reproducir_una_vez and Gamestateminijuegos.cinematicas_vistas.has(id_cinematica):
		_finalizar_directo()
		return

	await ejecutar_secuencia_intro()

# Lógica compartida de reproducción de diálogos
func reproducir_dialogo(recurso: DialogueResource) -> void:
	if not recurso: return
	
	MusicManager.fade_out(1.0)
	await DialogueManager.show_dialogue_balloon(recurso, "", [self])
	await DialogueManager.dialogue_ended
	MusicManager.fade_in(1.0)

# Métodos que los hijos pueden usar o sobreescribir
func ejecutar_secuencia_intro():
	await reproducir_dialogo(dialogue_intro)
	marcar_como_vista()
	cinematica_terminada.emit()

func marcar_como_vista():
	if reproducir_una_vez:
		Gamestateminijuegos.cinematicas_vistas[id_cinematica] = true

func cambiar_escena():
	if next_scene != "":
		SceneSwitcher2.change_to_file_with_transition(next_scene, spawn_point_path)

func _finalizar_directo():
	print("⏭️ Cinemática saltada (ya vista)")
	cinematica_terminada.emit()
