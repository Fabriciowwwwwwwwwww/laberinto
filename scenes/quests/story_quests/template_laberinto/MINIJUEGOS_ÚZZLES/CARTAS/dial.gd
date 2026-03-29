# Script de Dial.gd
extends HBoxContainer

signal valor_cambiado(nuevo_valor)

@onready var visual = $TextureRect # Asegúrate que se llame así
var simbolos = ["espada", "diamante", "corazon", "trebol"]
var texturas = {
	"diamante": preload("res://scenes/quests/story_quests/template_laberinto/sprite_laberinto/diamante.jpg"),
	"espada": preload("res://scenes/quests/story_quests/template_laberinto/sprite_laberinto/espada.png"),
	"corazon": preload("res://assets/third_party/inputs/keyboard-and-mouse/Dark/Arrow_Left_Key_Dark.png"),
	"trebol": preload("res://scenes/quests/story_quests/template_laberinto/sprite_laberinto/trebol.png")
}
var indice_actual = 0

func _ready():
	actualizar_vista()



func actualizar_vista():
	var nombre = simbolos[indice_actual]
	visual.texture = texturas[nombre]
	valor_cambiado.emit(nombre)

func get_valor():
	return simbolos[indice_actual]


func _on_flecha_arriba_pressed() -> void:
	indice_actual = (indice_actual + 1) % simbolos.size()
	actualizar_vista()



func _on_flecha_abajo_pressed() -> void:
	indice_actual = (indice_actual - 1)
	if indice_actual < 0: indice_actual = simbolos.size() - 1
	actualizar_vista()
