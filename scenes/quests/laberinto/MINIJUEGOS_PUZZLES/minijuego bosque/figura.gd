extends Area2D

@export var nombre_de_esta_pieza: String = "circulo"
@onready var audio = $AudioStreamPlayer2D

var player = null

func _ready():
	add_to_group("piezas_minijuego")
	
	audio.volume_db = -80
	audio.play()

	# 🔥 Buscar jugador automáticamente
	player = get_tree().get_first_node_in_group("player")


func _process(_delta):
	if not player:
		return
	
	var piezas = get_tree().get_nodes_in_group("piezas_minijuego")
	
	var mas_cercana = null
	var distancia_min = INF
	
	# 🔍 Buscar la pieza más cercana
	for p in piezas:
		if not is_instance_valid(p):
			continue
		
		var d = p.global_position.distance_to(player.global_position)
		if d < distancia_min:
			distancia_min = d
			mas_cercana = p
	
	# 🔥 SOLO LA MÁS CERCANA SUENA
	if mas_cercana == self:
		var distancia_max = 500.0
		var distancia_minima = 50.0
		
		var t = clamp((distancia_max - distancia_min) / (distancia_max - distancia_minima), 0.0, 1.0)
		
		audio.volume_db = lerp(-35.0, 5.0, t)
		audio.pitch_scale = lerp(0.9, 1.4, t)
	else:
		audio.volume_db = -80


# 🎯 RECOLECCIÓN (esto sí usa colisión)
func _on_body_entered(body):
	if body.is_in_group("player"):
		var reglas = body.get_node_or_null("MINIJUEGOREGLAS")
		if reglas:
			reglas.recoger_figura(nombre_de_esta_pieza)
			queue_free()
