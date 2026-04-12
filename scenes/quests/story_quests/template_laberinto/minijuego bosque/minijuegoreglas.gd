extends Node2D

# --- CONFIGURACIÓN ---
@onready var player = get_parent() 
@onready var heartbeat_sound = $HeartbeatSound
@onready var canvas_daño = get_tree().current_scene.get_node("CanvasLayer")
@onready var anim_daño = canvas_daño.get_node("CanvasLayer/AnimatedSprite2D")

# 🔥 LIMITES DEL BOSQUE
const LIMITE_MIN = Vector2(-1717.0, -1673.0)
const LIMITE_MAX = Vector2(4252.0, 4250.0)

var piezas_recolectadas: Array = []
var piezas_totales: int = 5
var cerca_de_cabaña: bool = false
var vida_previa: int = 0


func _ready():
	# 1. Configurar Audio
	if heartbeat_sound:
		heartbeat_sound.play()
		heartbeat_sound.volume_db = -80
	
	if player:
		vida_previa = player.vida_actual
	
	if canvas_daño:
		canvas_daño.visible = false

	# 2. CONEXIÓN AUTOMÁTICA DE PIEZAS
	var piezas = get_tree().get_nodes_in_group("piezas_minijuego")
	for pieza in piezas:
		if pieza is Area2D:
			pieza.body_entered.connect(_on_pieza_recolectada.bind(pieza))


func _process(_delta):
	if not player: return
	
	# 🔥 LIMITAR JUGADOR
	limitar_jugador()
	
	actualizar_latido_por_distancia()
	verificar_daño_jugador()
	verificar_interaccion_cabaña()


# 🔥 FUNCIÓN CLAMP
func limitar_jugador():
	player.global_position = Vector2(
		clamp(player.global_position.x, LIMITE_MIN.x, LIMITE_MAX.x),
		clamp(player.global_position.y, LIMITE_MIN.y, LIMITE_MAX.y)
	)


# --- RECOLECCIÓN ---
func _on_pieza_recolectada(body, pieza_nodo):
	if body == player and pieza_nodo.visible:
		var nombre = pieza_nodo.name
		if not piezas_recolectadas.has(nombre):
			piezas_recolectadas.append(nombre)
			print("Recolectado: ", nombre, " (Total: ", piezas_recolectadas.size(), "/22)")
			
			if player.current_door != null:
				player.current_door.check_door_status()
			
			pieza_nodo.z_index = 1
			var tween = get_tree().create_tween()
			tween.tween_property(pieza_nodo, "position", pieza_nodo.position + Vector2(0, -40), 0.3).set_trans(Tween.TRANS_ELASTIC)
			tween.parallel().tween_property(pieza_nodo, "modulate:a", 0.0, 0.3)
			
			tween.finished.connect(func(): pieza_nodo.queue_free())
			
			pieza_nodo.set_deferred("monitoring", false)
			pieza_nodo.set_deferred("monitorable", false)


# --- RESTO ---
func actualizar_latido_por_distancia():
	var enemigos = get_tree().get_nodes_in_group("enemy")
	var distancia_mas_cercana = 9999.0
	for enemigo in enemigos:
		var d = player.global_position.distance_to(enemigo.global_position)
		if d < distancia_mas_cercana:
			distancia_mas_cercana = d
	
	var radio_maximo = 600.0
	var radio_critico = 100.0
	if distancia_mas_cercana < radio_maximo:
		var t = clamp((radio_maximo - distancia_mas_cercana) / (radio_maximo - radio_critico), 0.0, 1.0)
		heartbeat_sound.volume_db = lerp(-40.0, 6.0, t)
		heartbeat_sound.pitch_scale = lerp(1.0, 1.8, t)
	else:
		heartbeat_sound.volume_db = -80.0


func verificar_daño_jugador():
	if player.vida_actual < vida_previa:
		mostrar_efecto_daño()
	vida_previa = player.vida_actual


func mostrar_efecto_daño():
	if canvas_daño:
		canvas_daño.visible = true
		if anim_daño: anim_daño.play("daño")
		await get_tree().create_timer(0.6).timeout
		canvas_daño.visible = false


func verificar_interaccion_cabaña():
	if Input.is_action_just_pressed("Interact") and cerca_de_cabaña:
		if piezas_recolectadas.size() >= piezas_totales:
			abrir_puerta_final()
		else:
			print("Aún te faltan ", piezas_totales - piezas_recolectadas.size(), " piezas.")


func abrir_puerta_final():
	print("¡CABAÑA ABIERTA!")
