extends Node2D

@export var next_scene_path: String

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var efecto: AnimatedSprite2D = $efecto
@onready var ui_final: CanvasLayer = $UI_Final

func _ready() -> void:
	ui_final.visible = false

	sprite.play("muerte")
	efecto.play("idle")

	sprite.animation_finished.connect(_on_animacion_terminada)


func _on_animacion_terminada() -> void:
	mostrar_estadisticas()


func mostrar_estadisticas() -> void:

	# 🔥 detener juego
	get_tree().paused = false

	ui_final.visible = true

	# rellenar datos
	$UI_Final/Panel/Enemigos2.text = "Enemigos: %d" % GameStateLaberinto.enemigos_eliminados
	$UI_Final/Panel/Puertas2.text = "Puertas: %d" % GameStateLaberinto.puertas_abiertas
	$UI_Final/Panel/Cofres2.text = "Cofres: %d" % GameStateLaberinto.cofres_abiertos
	$UI_Final/Panel/Experiencia2.text = "XP: %d" % GameStateLaberinto.experiencia_obtenida
	$UI_Final/Panel/puntos_recibido2.text = "Daño recibido: %d" % GameStateLaberinto.dano_recibido
	$UI_Final/Panel/Tiempo2.text = "Tiempo: %s" % GameStateLaberinto.tiempo_formateado()
func _input(event) -> void:
	if ui_final.visible and Input.is_action_just_pressed("Interact"):
		_on_menu_pressed()

func _on_menu_pressed() -> void:
	SceneSwitcher2.change_to_file_with_transition(
		next_scene_path,
		"",
		Transition.Effect.FADE,
		Transition.Effect.FADE
	)
