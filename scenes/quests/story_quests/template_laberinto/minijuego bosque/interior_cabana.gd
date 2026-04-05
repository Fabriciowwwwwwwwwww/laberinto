extends Node2D

@onready var area = $Area2D_Entrada

var puede_usar := true  # 🔥 LOCAL, no global

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not puede_usar:
		return

	if body.is_in_group("player"):

		puede_usar = false  # 🔥 bloquea SOLO esta puerta

		print("SALIENDO DE CABAÑA")

		Gamestateminijuegos.viene_de_interior = true

		SceneSwitcher2.change_to_file_with_transition(
			"res://scenes/quests/story_quests/template_laberinto/minijuego bosque/minijuego_bosque.tscn",
			"",
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
