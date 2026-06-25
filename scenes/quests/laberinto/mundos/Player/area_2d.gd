extends Area2D

@onready var xp_manager = get_parent().get_node("XPManager")

func _on_body_entered(body)-> void:

	if body.is_in_group("xp_orb"):

		if xp_manager:
			xp_manager.agregar_experiencia(body.xp_value)

		body.queue_free()
