extends Node2D

signal valor_cambiado(nuevo_valor)

@onready var visual: TextureRect = $dial/simbolo

var simbolos = ["espada", "diamante", "corazon", "trebol"]

var texturas = {
	"diamante": preload("res://scenes/quests/story_quests/template_laberinto/sprite_laberinto/cartas/carta diamante.png"),
	"espada": preload("res://scenes/quests/story_quests/template_laberinto/sprite_laberinto/cartas/carta espada.png"),
	"corazon": preload("res://scenes/quests/story_quests/template_laberinto/sprite_laberinto/cartas/carta corazon.png"),
	"trebol": preload("res://scenes/quests/story_quests/template_laberinto/sprite_laberinto/cartas/carta trebol.png"),
}

var indice_actual := 0

# -------------------------
# READY
# -------------------------
func _ready():
	actualizar_vista()

# -------------------------
# ACTUALIZAR VISTA
# -------------------------
func actualizar_vista():
	var nombre = simbolos[indice_actual]
	visual.texture = texturas[nombre]

	# 🔥 Notifica al sistema principal
	valor_cambiado.emit(nombre)

# -------------------------
# GET VALOR ACTUAL
# -------------------------
func get_valor() -> String:
	return simbolos[indice_actual]

# -------------------------
# BOTON ARRIBA
# -------------------------
func _on_flecha_arriba_pressed() -> void:
	indice_actual = (indice_actual + 1) % simbolos.size()
	actualizar_vista()

# -------------------------
# BOTON ABAJO
# -------------------------
func _on_flecha_abajo_pressed() -> void:
	indice_actual -= 1
	if indice_actual < 0:
		indice_actual = simbolos.size() - 1
	
	actualizar_vista()
