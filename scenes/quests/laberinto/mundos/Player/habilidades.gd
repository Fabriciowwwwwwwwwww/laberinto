extends Node
class_name PlayerHabilidades

var puede_usar_veneno := true
var puede_usar_bomba := true


func activar_veneno()-> void:

	puede_usar_veneno = true

	print("VENENO LISTO")


func activar_bomba()-> void:

	puede_usar_bomba = true

	print("BOMBA LISTA")
