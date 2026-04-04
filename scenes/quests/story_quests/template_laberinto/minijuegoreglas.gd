extends Node2D 


func _ready():
	add_to_group("player")
	if Gamestateminijuegos.viene_de_cabana:
		global_position = Gamestateminijuegos.posicion_salida
		Gamestateminijuegos.viene_de_cabana = false
