extends Node2D 

@export var next_scene_path: String

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var efecto: AnimatedSprite2D = $efecto
func _ready() -> void:
	sprite.play("muerte")
	efecto.play("idle")
	sprite.animation_finished.connect(_on_animacion_terminada)

func _on_animacion_terminada():
	cambiar_escena()

func cambiar_escena():
	if next_scene_path == "":
		print("❌ No asignaste escena")
		return
	
	SceneSwitcher2.change_to_file_with_transition(
		next_scene_path,
		"",
		Transition.Effect.FADE,
		Transition.Effect.FADE
	)
