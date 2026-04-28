extends Control

@onready var lupa = $"../lupa"
@export var radio_lupa := 80
var activo := false

func _process(delta):
	if not activo:
		return
	
	var lupa_pos = lupa.global_position
	
	for obj in get_tree().get_nodes_in_group("revelables"):
		obj.actualizar_revelado(lupa_pos, radio_lupa)
	
	queue_redraw()

func _draw():
	if not activo:
		return
	
	var lupa_pos = get_global_transform_with_canvas().affine_inverse() * lupa.global_position
	draw_circle(lupa_pos, radio_lupa, Color(1,1,1,0.15))
