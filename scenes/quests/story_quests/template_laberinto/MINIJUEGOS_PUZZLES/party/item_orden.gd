extends Control

@export var id_correcto := 0
@export var textura: Texture2D

@onready var sprite = $Texture

var dragging := false
var offset := Vector2.ZERO

# -------------------------
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

	if textura:
		sprite.texture = textura

# -------------------------
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			dragging = true
			offset = get_global_mouse_position() - global_position
			z_index = 100
		else:
			dragging = false
			z_index = 0

	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - offset

# -------------------------
func get_texture():
	return sprite.texture
