extends Node2D

# --- CONFIGURACIÓN ---
@onready var player = get_parent() 
@onready var heartbeat_sound = $HeartbeatSound
@onready var keys_label = get_tree().current_scene.get_node("Llaves/Keys_label") as Label
@onready var canvas_daño = get_tree().current_scene.get_node("CanvasLayer")
@onready var anim_daño = canvas_daño.get_node("CanvasLayer/AnimatedSprite2D")
@onready var alma_sound = $AlmaSound

# 🔥 UNA SOLA FUENTE DE VERDAD
const PIEZAS_NECESARIAS = 8

# 🔥 LIMITES DEL BOSQUE
const LIMITE_MIN = Vector2(-1717.0, -1673.0)
const LIMITE_MAX = Vector2(4252.0, 4250.0)

var piezas_recolectadas: Array = []
var vida_previa: int = 0
var cerca_de_cabaña: bool = false


func _ready():
	# 🔥 UI INICIAL
	if keys_label:
		keys_label.text = "Almas: 0 / " + str(PIEZAS_NECESARIAS)

	# 🔊 Sonido almas
	if alma_sound:
		alma_sound.play()
		alma_sound.volume_db = -80

	# ❤️ Latido
	if heartbeat_sound:
		heartbeat_sound.play()
		heartbeat_sound.volume_db = -80
	
	if player:
		vida_previa = player.vida_actual
	if player:
		player.connect("jugador_derrotado", Callable(self, "_on_jugador_muerto"))
	if canvas_daño:
		canvas_daño.visible = false

	# 🔥 Conectar piezas
	var piezas = get_tree().get_nodes_in_group("piezas_minijuego")
	for pieza in piezas:
		if pieza is Area2D:
			pieza.body_entered.connect(_on_pieza_recolectada.bind(pieza))


func _process(_delta):
	limitar_jugador()
	actualizar_latido_por_distancia()
	actualizar_sonido_piezas()
	verificar_daño_jugador()
	verificar_interaccion_cabaña()


# 🔥 LIMITES
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

			# 🔥 ACTUALIZAR UI
			if keys_label:
				keys_label.text = "Almas: " + str(piezas_recolectadas.size()) + " / " + str(PIEZAS_NECESARIAS)

			print("Recolectado: ", nombre)

			# 🔥 ACTUALIZAR PUERTA
			if player.current_door != null:
				player.current_door.check_door_status()

			# animación
			pieza_nodo.z_index = 1
			var tween = get_tree().create_tween()
			tween.tween_property(pieza_nodo, "position", pieza_nodo.position + Vector2(0, -40), 0.3)
			tween.parallel().tween_property(pieza_nodo, "modulate:a", 0.0, 0.3)

			tween.finished.connect(func(): pieza_nodo.queue_free())

			pieza_nodo.set_deferred("monitoring", false)
			pieza_nodo.set_deferred("monitorable", false)


# --- SONIDO ENEMIGOS ---
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


# --- SONIDO ALMAS ---
func actualizar_sonido_piezas():
	var piezas = get_tree().get_nodes_in_group("piezas_minijuego")
	var distancia_min = INF

	for pieza in piezas:
		if not is_instance_valid(pieza):
			continue
		
		var d = player.global_position.distance_to(pieza.global_position)
		if d < distancia_min:
			distancia_min = d

	if distancia_min == INF:
		alma_sound.volume_db = -80
		return
	
	var t = clamp((600.0 - distancia_min) / (600.0 - 50.0), 0.0, 1.0)

	alma_sound.volume_db = lerp(-40.0, 6.0, t)
	alma_sound.pitch_scale = lerp(0.8, 1.5, t)


# --- DAÑO ---
func verificar_daño_jugador():
	if player.vida_actual < vida_previa:
		mostrar_efecto_daño()
	vida_previa = player.vida_actual


func mostrar_efecto_daño():
	if canvas_daño:
		canvas_daño.visible = true
		if anim_daño:
			anim_daño.play("daño")
		await get_tree().create_timer(0.6).timeout
		canvas_daño.visible = false


# --- CABAÑA ---
func verificar_interaccion_cabaña():
	if Input.is_action_just_pressed("Interact") and cerca_de_cabaña:
		if piezas_recolectadas.size() >= PIEZAS_NECESARIAS:
			abrir_puerta_final()
		else:
			print("Faltan ", PIEZAS_NECESARIAS - piezas_recolectadas.size(), " piezas")

func _on_jugador_muerto():
	print("💀 muerte detectada en minijuego")

	# 🔥 DETENER CAMBIO DE ESCENA
	get_tree().paused = true

	await get_tree().process_frame
	get_tree().paused = false

	reiniciar_minijuego()
func abrir_puerta_final():
	print("¡CABAÑA ABIERTA!")
func reiniciar_minijuego():

	print("🔄 reiniciando minijuego")

	# 🔥 reset variables
	piezas_recolectadas.clear()

	if keys_label:
		keys_label.text = "Almas: 0 / " + str(PIEZAS_NECESARIAS)

	# 🔥 reset vida
	if player:
		player.vida_actual = player.vida_maxima

	# 🔥 recargar escena actual (CLAVE)
	get_tree().reload_current_scene()
