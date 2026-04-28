# MinigameState.gd
extends Node
var cinematicas_vistas := {}
var posicion_entrada_exterior: Vector2 = Vector2.ZERO
var posicion_salida_interior: Vector2 = Vector2.ZERO

var viene_de_exterior := false
var viene_de_interior := false

var piezas_recogidas: Array = []
var total_piezas := 3
# 🔥 ESTA ES LA QUE FALTA
var puede_teletransportar := true
