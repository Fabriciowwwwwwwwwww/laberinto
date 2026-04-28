extends Area2D

@export var index: int = 0

@onready var sonido_seleccion: AudioStreamPlayer2D = $sonido_seleccion
@onready var imagen: Sprite2D = $carta

var simbolo: String

var simbolos = ["espada", "diamante", "corazon", "trebol"]

var texturas = {
	"diamante": preload("res://scenes/quests/laberinto/sprite_laberinto/cartas/carta diamante.png"),
	"espada": preload("res://scenes/quests/laberinto/sprite_laberinto/cartas/carta espada.png"),
	"corazon": preload("res://scenes/quests/laberinto/sprite_laberinto/cartas/carta corazon.png"),
	"trebol": preload("res://scenes/quests/laberinto/sprite_laberinto/cartas/carta trebol.png"),
}

var escala_original := Vector2.ONE
var tween: Tween
var seleccionada := false

# -------------------------
# READY
# -------------------------
func _ready():
	escala_original = scale
	
	randomizar_simbolo() # 🔥 CLAVE
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

# -------------------------
# RANDOM SIMBOLO
# -------------------------
func randomizar_simbolo():
	var random_index = randi() % simbolos.size()
	simbolo = simbolos[random_index]
	
	imagen.texture = texturas[simbolo]

# -------------------------
# RESET VISUAL
# -------------------------
func resetear():
	seleccionada = false
	scale = escala_original
	modulate = Color(1,1,1)

	# 🔥 OPCIONAL: si quieres que cambie cada ronda
	randomizar_simbolo()

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
