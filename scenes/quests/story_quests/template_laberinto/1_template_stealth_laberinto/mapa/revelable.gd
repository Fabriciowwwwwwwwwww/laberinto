extends Area2D

@export var textura_icono: Texture2D
@onready var sprite: Sprite2D = $Sprite2D

var descubierto := false

func _ready():
	add_to_group("revelables")
	sprite.texture = textura_icono
	sprite.visible = false
	
	input_event.connect(_on_click)

# 🔥 ESTA FUNCIÓN LA LLAMA EL MAPA
func actualizar_revelado(mouse_pos: Vector2, radio: float):
	if descubierto:
		return
	
	var distancia = global_position.distance_to(mouse_pos)
	
	if distancia < radio:
		sprite.visible = true
		modulate = Color(1,1,1,0.6) # preview
	else:
		sprite.visible = false

# CLICK PARA FIJAR
func _on_click(viewport, event, shape_idx):
	if descubierto:
		return

	if InputManager.is_pressed(event):
		descubrir()

func descubrir():
	descubierto = true
	sprite.visible = true
	modulate = Color(1,1,1,1)
