extends Node2D
class_name cinematica

signal cinematica_terminada

## Diálogo inicial
@export var dialogue: DialogueResource = preload("res://scenes/ui_elements/cinematic/dialogos_puzzle/ganzuas/intro_ganzuas.dialogue")

## Diálogos adicionales
@export var tiempo_dialogue: DialogueResource
@export var perder_dialogue: DialogueResource
@export var ganar_dialogue: DialogueResource

@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String

var primera_vez := true
var perdidas: int = 0
var ha_ganado: bool = false


func _ready() -> void:
	add_to_group("cinematica")

	# Mostrar diálogo inicial
	if dialogue:
		await DialogueManager.show_dialogue_balloon(dialogue, "", [self])
		await DialogueManager.dialogue_ended

	cinematica_terminada.emit()


func mostrar_dialogo_por_evento() -> void:

	var dialogo: DialogueResource

	if ha_ganado:
		dialogo = ganar_dialogue
	elif perdidas == 1:
		dialogo = tiempo_dialogue
	else:
		dialogo = perder_dialogue

	if dialogo == null:
		print("⚠️ diálogo no asignado")
		return

	await DialogueManager.show_dialogue_balloon(dialogo, "", [self])
	await DialogueManager.dialogue_ended

	cinematica_terminada.emit()


func notificar_perdida() -> void:
	perdidas += 1
	await mostrar_dialogo_por_evento()


func notificar_ganador() -> void:
	ha_ganado = true
	await mostrar_dialogo_por_evento()
	_on_cambio_de_escena()


func _on_cambio_de_escena() -> void:
	if next_scene != "":
		SceneSwitcher2.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
