extends Area2D

@export var id := ""

func _ready():
	add_to_group("pieza_llave")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):

		if id != "":
			if id in Gamestateminijuegos.piezas_recogidas:
				queue_free()
				return

			Gamestateminijuegos.piezas_recogidas.append(id)

		print("🔑 Pieza recogida:", id)

		queue_free()
