extends Sprite2D
var usando_mando := false
var target_position := Vector2.ZERO
var pestillo_objetivo: Node2D = null

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

	if usando_mando:

		global_position = global_position.lerp(
			target_position,
			15.0 * delta
		)

	else:

		var objetivo: Vector2

		if usando_touch:

			var cam = get_viewport().get_camera_2d()

			if cam:
				objetivo = cam.get_screen_to_world(last_touch_pos)
			else:
				objetivo = last_touch_pos

		else:

			objetivo = get_global_mouse_position()

		global_position = global_position.lerp(
			objetivo,
			15.0 * delta
		)
