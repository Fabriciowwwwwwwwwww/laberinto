extends Control
class_name ItemOrden

@export var id_correcto := 0
@export var textura: Texture2D

var sprite: TextureRect
var dragging := false
var offset := Vector2.ZERO
var slot_actual = null

var posicion_inicial: Vector2  # 🔥 FALTABA ESTO

# -------------------------
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	top_level = true  # 🔥 CLAVE

	sprite = get_node("Texture")

	custom_minimum_size = Vector2(120, 120)

	if textura:
		sprite.texture = textura

# -------------------------
func _gui_input(event):

	if event is InputEventMouseButton:

		if event.pressed:
			dragging = true
			offset = get_global_mouse_position() - global_position
			z_index = 100

			# 🔥 LIBERAR SLOT AL AGARRAR
			if slot_actual:
				slot_actual.item_actual = null
				slot_actual = null

			accept_event()

		else:
			dragging = false
			z_index = 0
			accept_event()

	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - offset
		accept_event()

# -------------------------
