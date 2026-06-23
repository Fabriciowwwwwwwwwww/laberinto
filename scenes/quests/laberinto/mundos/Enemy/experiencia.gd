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

		orb.global_position = global_position

		orb.xp_value = randi_range(min_xp, max_xp)
