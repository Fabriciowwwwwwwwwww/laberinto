extends Control

@export var radio_lupa := 80
var activo := false

func _process(delta):
	if activo:
		queue_redraw()

func _draw():
	if not activo:
		return
	
	var mouse_pos = get_local_mouse_position()
	draw_circle(mouse_pos, radio_lupa, Color(1,1,1,0.15))
