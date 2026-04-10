extends Area2D

@export var nombre_de_esta_pieza: String = "circulo" # Cambia esto en el inspector para cada una

func _on_body_entered(body):
	# Buscamos el nodo de reglas dentro del jugador
	var reglas = body.get_node_or_null("MINIJUEGOREGLAS")
	if reglas:
		reglas.recoger_figura(nombre_de_esta_pieza)
		queue_free() # La pieza desaparece
