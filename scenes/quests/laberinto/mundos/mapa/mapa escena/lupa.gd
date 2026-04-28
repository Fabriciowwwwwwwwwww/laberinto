extends TextureRect

enum State {
	IDLE,
	DRAGGING,
	RETURNING
}

var state = State.IDLE

var offset := Vector2.ZERO
var origin := Vector2.ZERO

# movimiento idle
var idle_time := 0.0

# velocidad de regreso
var return_speed := 5.0

func _ready():
	origin = position

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			state = State.DRAGGING
			offset = get_global_mouse_position() - global_position
		else:
			if state == State.DRAGGING:
				state = State.RETURNING

func _process(delta):
	match state:
		
		State.IDLE:
			idle_time += delta
			
			# 👇 pequeño movimiento flotante
			var float_x = sin(idle_time * 2.0) * 5
			var float_y = cos(idle_time * 2.5) * 5
			
			position = origin + Vector2(float_x, float_y)
		
		
		State.DRAGGING:
			global_position = get_global_mouse_position() - offset
		
		
		State.RETURNING:
			position = position.lerp(origin, return_speed * delta)
			
			# cuando llega, vuelve a idle
			if position.distance_to(origin) < 2:
				state = State.IDLE
