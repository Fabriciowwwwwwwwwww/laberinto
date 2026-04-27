extends Node

var es_movil := OS.has_feature("mobile")

# -------------------------
# 🎯 INPUT PRINCIPAL (CLICK / TAP / ENTER)
func is_accept(event: InputEvent) -> bool:
	# Mouse izquierdo
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	# Touch
	if event is InputEventScreenTouch:
		return event.pressed

	# Teclado / mando
	return Input.is_action_just_pressed("ui_accept")

# -------------------------
# ❌ CANCELAR / SKIP
func is_cancel(event: InputEvent) -> bool:
	# Mouse derecho
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_RIGHT

	# Teclado / mando
	return Input.is_action_just_pressed("ui_cancel")

# -------------------------
# 🖱️ PRESIONADO GENERICO


func is_pressed(event) -> bool:
	return (
		(event is InputEventMouseButton and event.pressed) or
		(event is InputEventScreenTouch and event.pressed)
	)

func is_released(event) -> bool:
	return (
		(event is InputEventMouseButton and not event.pressed) or
		(event is InputEventScreenTouch and not event.pressed)
	)

func is_drag(event) -> bool:
	return (
		event is InputEventMouseMotion or
		event is InputEventScreenDrag
	)

func get_position(event) -> Vector2:
	if event is InputEventMouse:
		return event.position
	if event is InputEventScreenTouch:
		return event.position
	if event is InputEventScreenDrag:
		return event.position
	return Vector2.ZERO

# -------------------------
# 🎮 MOVIMIENTO (TECLADO / JOYSTICK)
func get_vector() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

# -------------------------
# 🔥 MANTENER PRESIONADO (IMPORTANTE PARA MOBILE)
func is_accept_pressed() -> bool:
	return Input.is_action_pressed("ui_accept")

# -------------------------
# 🔥 CLICK RAPIDO (evita spam)
func is_accept_just_pressed() -> bool:
	return Input.is_action_just_pressed("ui_accept")
