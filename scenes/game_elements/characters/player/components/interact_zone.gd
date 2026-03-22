extends Area2D

@export var character: CharacterBody2D

var is_looking_from_right: bool = false


func _ready() -> void:
	if not character and owner is CharacterBody2D:
		character = owner


func get_interact_area() -> Area2D:
	var areas := get_overlapping_areas()
	var best: Area2D = null
	var best_distance: float = INF

	for area in areas:
		var distance := global_position.distance_to(area.global_position)
		if not best or distance < best_distance:
			best_distance = distance
			best = area

	return best


func _process(_delta: float) -> void:
	if not character:
		return
	if not monitoring:
		return

	if not is_zero_approx(character.velocity.x):
		if character.velocity.x < 0:
			scale.x = -1
		else:
			scale.x = 1

		is_looking_from_right = scale.x < 0
