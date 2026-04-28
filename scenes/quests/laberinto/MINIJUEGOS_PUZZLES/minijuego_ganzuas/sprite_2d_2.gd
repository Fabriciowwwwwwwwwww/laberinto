extends Sprite2D

var last_touch_pos: Vector2 = Vector2.ZERO
var usando_touch := false

func _input(event):
	# 📱 detectar dedo
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		last_touch_pos = event.position
		usando_touch = true

	# 📱 cuando suelta el dedo
	if event is InputEventScreenTouch and not event.pressed:
		usando_touch = false
		last_touch_pos = Vector2.ZERO

func _process(delta: float) -> void:

	var objetivo: Vector2

	if usando_touch:
		var cam = get_viewport().get_camera_2d()
		if cam:
			objetivo = cam.get_screen_to_world(last_touch_pos)
		else:
			objetivo = last_touch_pos
	else:
		# 🖥️ PC
		objetivo = get_global_mouse_position()

	position = position.lerp(objetivo, 15 * delta)
