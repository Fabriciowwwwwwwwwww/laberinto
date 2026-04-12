
extends Control

@export var next_scene: PackedScene
@export var tienda: PackedScene
@onready var main_menu = $MainMenu
@onready var options = $"../Options"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()




func _on_main_menu_options_pressed() -> void:
	main_menu.hide()
	options.show()


func _on_main_menu_credits_pressed() -> void:
	main_menu.hide()

func _on_credits_back() -> void:
	main_menu.show()

func _on_options_back() -> void:
	options.hide()
	main_menu.show()

func _on_main_menu_start_pressed() -> void:
	(
		SceneSwitcher2
		. change_to_packed_with_transition(
			next_scene,
			^"",
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
	)


func _on_main_menu_tienda_pressed() -> void:
	(
		SceneSwitcher2
		. change_to_packed_with_transition(
			tienda,
			^"",
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
	)
