extends Node2D

@onready var area = $Area2D_Entrada

func _ready():
	area.body_entered.connect(_on_body_entered)
var puede_usar := true

func _on_body_entered(body):
	if not puede_usar:
		return

	if body.is_in_group("player"):

		puede_usar = false

		print("ENTRANDO A CABAÑA")

		Gamestateminijuegos.posicion_entrada_exterior = body.global_position
		Gamestateminijuegos.viene_de_exterior = true

		SceneSwitcher2.change_to_file_with_transition(
			"res://scenes/quests/story_quests/template_laberinto/minijuego bosque/InteriorCabana.tscn",
			"",
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
