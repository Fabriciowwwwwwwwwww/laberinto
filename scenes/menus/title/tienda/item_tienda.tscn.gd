extends Control

@onready var icono = $TextureRect
@onready var label = $Label

func _ready():
	# 🔥 ESTO ES LO MÁS IMPORTANTE
	custom_minimum_size = Vector2(150, 150)

	# opcional: centrar contenido
	icono.expand = true
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
