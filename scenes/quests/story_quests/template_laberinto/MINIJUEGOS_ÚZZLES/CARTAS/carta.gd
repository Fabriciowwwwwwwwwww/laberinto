extends Area2D

@export var index: int = 0
@onready var sonido_seleccion: AudioStreamPlayer2D =$sonido_seleccion

var escala_original := Vector2.ONE
var tween: Tween
var seleccionada := false

func _ready():
	escala_original = scale
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

# -------------------------
# RESET VISUAL
# -------------------------
func resetear():
	seleccionada = false
	scale = escala_original
	modulate = Color(1,1,1)

# -------------------------
# HOVER
# -------------------------
func _on_mouse_entered():
	if tween:
		tween.kill()
	
	tween = create_tween()
	sonido_seleccion.play()
	tween.tween_property(self, "scale", escala_original * 1.1, 0.15)
	tween.parallel().tween_property(self, "modulate", Color(1.2,1.2,1.2), 0.15)

func _on_mouse_exited():
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "scale", escala_original, 0.15)
	
	if seleccionada:
		tween.parallel().tween_property(self, "modulate", Color(1.5,1.5,0.8), 0.15)
	else:
		tween.parallel().tween_property(self, "modulate", Color(1,1,1), 0.15)

# -------------------------
# CLICK
# -------------------------
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		
		seleccionada = !seleccionada
		
		if seleccionada:
			modulate = Color(1.5,1.5,0.8)
		else:
			modulate = Color(1,1,1)
		
		var puzzle = get_tree().get_first_node_in_group("puzzle")
		if puzzle:
			puzzle.seleccionar_carta(index)
