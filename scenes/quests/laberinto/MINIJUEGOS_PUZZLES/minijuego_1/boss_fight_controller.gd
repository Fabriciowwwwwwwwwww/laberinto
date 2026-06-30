
extends Node2D




var boss_lives := 3

func _ready():

	Gamestateminijuegos.current_lives = boss_lives

func player_dead() -> void:

	Gamestateminijuegos.current_lives -= 1

	print("Intentos restantes: ", GameState.current_lives)

	if Gamestateminijuegos.current_lives <= 0:

		print("PERDISTE")
