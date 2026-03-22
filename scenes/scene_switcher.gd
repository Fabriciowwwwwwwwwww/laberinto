extends Node
class_name SceneSwitcher

func change_to_file_with_transition(scene_path: String, spawn_point := "", in_effect: Variant = null, out_effect: Variant = null):
	get_tree().change_scene_to_file(scene_path)
