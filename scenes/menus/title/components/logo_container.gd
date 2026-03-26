extends Control

func _ready():
	flotar()
func flotar():
	var tween = create_tween()
	tween.set_loops()
	
	var pos_inicial = position
	
	tween.tween_property(self, "position:y", pos_inicial.y - 10, 1.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.05, 1.05), 1.2)
	
	tween.tween_property(self, "position:y", pos_inicial.y + 10, 1.2)
	tween.parallel().tween_property(self, "scale", Vector2(1, 1), 1.2)
