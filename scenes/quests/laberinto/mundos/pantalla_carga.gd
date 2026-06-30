extends Node2D

var next_scene_path: PackedScene = preload("res://scenes/menus/title/components/main_menu.tscn")

@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	anim.play("fade_out")
	await anim.animation_finished
	anim.play("fade_in")
	await anim.animation_finished
	change_scene()


func change_scene() -> void:
	print("Intentando cargar: ", next_scene_path)
	SceneSwitcher2.change_to_packed_with_transition(
		next_scene_path, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
