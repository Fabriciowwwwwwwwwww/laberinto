extends Node

var cinematicas_vistas := {}
var changing_scene := false
var posicion_entrada_exterior: Vector2 = Vector2.ZERO
var posicion_salida_interior: Vector2 = Vector2.ZERO

var viene_de_exterior := false
var viene_de_interior := false

var piezas_recogidas: Array = []
var total_piezas := 3

var puede_teletransportar := true

# 🔥 VIDA DEL BOSS / INTENTOS
var boss_lives := 3
var current_lives := 3
