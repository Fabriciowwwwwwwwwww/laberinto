extends Node

var experiencia: int = 0

signal experiencia_cambiada(experiencia)

func agregar_experiencia(cantidad: int)-> void:
	experiencia += cantidad

	print("XP TOTAL:", experiencia)

	emit_signal(
		"experiencia_cambiada",
		experiencia
	)
