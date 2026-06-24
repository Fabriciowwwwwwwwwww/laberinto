extends Node2D

@export var xp_orb_scene: PackedScene
@export var min_xp: int = 5
@export var max_xp: int = 13
@export var cantidad_min: int = 1
@export var cantidad_max: int = 3

func soltar_xp():

	var cantidad = randi_range(cantidad_min, cantidad_max)

	for i in range(cantidad):

		var orb = xp_orb_scene.instantiate()

		get_tree().current_scene.call_deferred("add_child", orb)

		# 🔥 ligera variación de posición (evita stacking)
		orb.global_position = global_position + Vector2(
			randf_range(-8, 8),
			randf_range(-8, 8)
		)

		# 🔥 XP aleatoria
		orb.xp_value = randi_range(min_xp, max_xp)

		# 🔥 dirección controlada (explosión bonita)
		var angle = randf_range(0, TAU)

		# evita dispersión extrema
		var radius = randf_range(0.3, 1.0)

		var dir = Vector2(cos(angle), sin(angle)) * radius
		dir = dir.normalized()
