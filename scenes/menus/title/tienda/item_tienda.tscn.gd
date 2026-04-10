extends Control

@onready var icono = $texturaitem
@onready var label = $Label

@export var sprite_frames: SpriteFrames  # 👈 EL .tres
@export var nombre_skin: String

func _ready():
	custom_minimum_size = Vector2(150, 150)

	icono.expand = true
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
