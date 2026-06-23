extends Node2D
@onready var canvas_final: CanvasLayer = $"../CajaFuerte"
@onready var contenedor_diales: HBoxContainer = $"../CajaFuerte/HBoxContainer"
var input_usuario: Array = []
var secuencia_simbolos: Array = []
# Diccionario para cargar las imágenes de los símbolos
var carta_seleccionada := 0
@export var tiempo_total: float = 15.0
@export var victorias_necesarias: int = 3
@export var music_tracks: Array[AudioStream]
var primera_ejecucion: bool = true
var cinematic_node: Node
var cartas_nodos: Array = []
@onready var cronometro: Timer = $"../Cronometro"
@onready var label_cronometro: Label = $"../ScreenOverlay/CronometroLabel"
@onready var animacion: AnimatedSprite2D = $animacion_cartas
@export var dial_scene: PackedScene # Arrastra Dial.tscn aquí en el inspector
# LABELS
@onready var label_carta1_arriba: Label = $"carta/label_carta_1_parte de arriba"
@onready var label_carta1_abajo: Label = $"carta/label_carta_1_parte de abajo"
@onready var label_carta2_arriba: Label = $"carta2/label_carta_2_parte de arriba"
@onready var label_carta2_abajo: Label = $"carta2/label_carta_2_parte de abajo"
@onready var label_carta3_arriba: Label = $"carta3/label_carta_3_parte de arriba"
@onready var label_carta3_abajo: Label = $"carta3/label_carta_3_parte de abajo"
@onready var label_carta4_arriba: Label = $"carta4/label_carta_4_parte de arriba"
@onready var label_carta4_abajo: Label = $"carta4/label_carta_4_parte de abajo"

@onready var sonido_cartas: AudioStreamPlayer2D = $"../cartas"
@onready var sonido_barajar: AudioStreamPlayer2D = $"../barajar"

# LOGICA
var tiempo_restante: float
var puzzle_activo: bool = false
var ha_interactuado: bool = false

var valores_cartas: Array = []
var seleccionadas: Array = []

var objetivo: int = 0
var tipo_operacion: String = ""

var victorias_actuales: int = 0

# -------------------------
# READY
# -------------------------
func _ready():

	var caja_fuerte = get_node("../CajaFuerte") 
	caja_fuerte.visible = false
	add_to_group("puzzle")
	secuencia_simbolos.clear()

	for n in get_tree().get_nodes_in_group("cartas"):
		cartas_nodos.append(n)
	actualizar_seleccion_mando()
	resetear_cartas()
	cronometro.wait_time = 1.0
	cronometro.timeout.connect(_on_cronometro_tick)

	await get_tree().process_frame
	cinematic_node = get_tree().get_first_node_in_group("cinematica")

	# Generamos la solución inicial para la cinemática
	generate_solution()

	if cinematic_node:
		cinematic_node.set_solucion([], tipo_operacion, objetivo)

	await iniciar_intro()
# INTRO
# -------------------------
func iniciar_intro() -> void:
	if cinematic_node:
		await cinematic_node.cinematica_terminada

	MusicManager.play_playlist(music_tracks)
	await iniciar_flujo()

# -------------------------
# FLUJO
# -------------------------
func iniciar_flujo() -> void:
	iniciar_puzzle()
	await get_tree().create_timer(0.2).timeout
	iniciar_tiempo()

# -------------------------
# INICIO
# ----------------------
# GENERAR SOLUCIÓN SEGURA
# -------------------------
func generate_solution() -> void:
	valores_cartas.clear()

	# 1. Decidir el tipo de operación
	var tipo = randi_range(0, 1)

	var a: int
	var b: int

	if tipo == 0:
		tipo_operacion = "POTENCIA"

		# Bases pequeñas para evitar números enormes
		var opciones = [
			[2,2],   # 4
			[2,3],   # 8
			[2,4],   # 16
			[2,5],   # 32

			[3,2],   # 9
			[3,3],   # 27

			[4,3],   # 64

			[5,2],   # 25
			[5,3],   # 125

			[6,2],   # 36
			[6,3],   # 216

			[7,2],   # 49

			[9,2],   # 81

			[10,2],  # 100

			[11,2],  # 121

			[12,2]   # 144
		]

		var seleccion = opciones.pick_random()

		a = seleccion[0]
		b = seleccion[1]

		objetivo = int(pow(a, b))

	else:
		tipo_operacion = "MULTIPLICA"

		a = randi_range(1, 5)
		b = randi_range(1, 5)

		while b == a:
			b = randi_range(1, 5)

		objetivo = a * b

	valores_cartas.append(a)
	valores_cartas.append(b)

	# 3. Llenar el resto con números que NO estén ya en el array
	# Creamos una lista de posibles candidatos (ej. del 1 al 12)
	var candidatos = []
	for n in range(1, 13):
		if n != a and n != b:
			candidatos.append(n)
	
	candidatos.shuffle() # Mezclamos los candidatos

	# Sacamos los que faltan para completar 4 cartas
	while valores_cartas.size() < 4:
		valores_cartas.append(candidatos.pop_back())

	# 4. Mezclar el orden final de las cartas 
	# (para que la solución no esté siempre en las primeras dos)
	valores_cartas.shuffle()

	actualizar_labels()

	print("🎯 Nueva ronda:", tipo_operacion, "Objetivo:", objetivo)
	print("🃏 Cartas únicas:", valores_cartas)
# -------------------------
# LABELS
# -------------------------
func actualizar_labels():
	label_carta1_arriba.text = str(valores_cartas[0])
	label_carta1_abajo.text = str(valores_cartas[0])
	label_carta2_arriba.text = str(valores_cartas[1])
	label_carta2_abajo.text = str(valores_cartas[1])
	label_carta3_arriba.text = str(valores_cartas[2])
	label_carta3_abajo.text = str(valores_cartas[2])
	label_carta4_arriba.text = str(valores_cartas[3])
	label_carta4_abajo.text = str(valores_cartas[3])

# -------------------------
# INPUT
# -------------------------
func seleccionar_carta(index) -> void:
	if not puzzle_activo:
		return

	if index in seleccionadas:
		seleccionadas.erase(index)
	else:
		seleccionadas.append(index)

	ha_interactuado = true

# -------------------------
# ENTER
# -------------------------
func _input(event) -> void:
	if canvas_final.visible and event.is_action_pressed("undo"):

		await _on_confirmar_pressed()
		return
	if not puzzle_activo:
		return

	# Mover selección
	if event.is_action_pressed("ui_left"):
		carta_seleccionada -= 1

		if carta_seleccionada < 0:
			carta_seleccionada = cartas_nodos.size() - 1

		actualizar_seleccion_mando()
		return

	if event.is_action_pressed("ui_right"):
		carta_seleccionada += 1

		if carta_seleccionada >= cartas_nodos.size():
			carta_seleccionada = 0

		actualizar_seleccion_mando()
		return

	# X / Interact → seleccionar carta
	if event.is_action_pressed("Interact"):

		if cartas_nodos.is_empty():
			return

		cartas_nodos[carta_seleccionada].activar_desde_mando()

		actualizar_seleccion_mando()

		return

	# O / Círculo → evaluar
	if event.is_action_pressed("undo") \
	or event.is_action_pressed("ui_accept"):

		if not ha_interactuado:
			return

		puzzle_activo = false

		ocultar_cartas()

		await get_tree().process_frame

		animacion.play("esconder_cartas")
		await animacion.animation_finished

		await verificar()

# -------------------------
# VERIFICAR
# -------------------------
func verificar() -> void:
	var resultado = 0

	if tipo_operacion == "POTENCIA":

		if seleccionadas.size() != 2:
			await perder("error")
			return

		var a = valores_cartas[seleccionadas[0]]
		var b = valores_cartas[seleccionadas[1]]

		resultado = int(pow(a, b))

	elif tipo_operacion == "MULTIPLICA":

		resultado = 1

		for i in seleccionadas:
			resultado *= valores_cartas[i]

	print("Resultado:", resultado, "Objetivo:", objetivo)

	if resultado == objetivo:
		await ganar()
	else:
		await perder("error")

# -------------------------
# GUARDAR (FIX CLAVE)
# -------------------------
func guardar_seleccion() -> void:
	for i in seleccionadas:
		var carta = cartas_nodos[i]
		secuencia_simbolos.append(str(carta.simbolo))

	print("🧠 Secuencia correcta:", secuencia_simbolos)

# -------------------------
# GANAR

# -------------------------
# PERDER
# -------------------------
# -------------------------
# TIEMPO
# -------------------------
func _on_cronometro_tick() -> void:
	if not puzzle_activo:
		return

	tiempo_restante -= 1
	label_cronometro.text = "Tiempo: %02d" % int(tiempo_restante)

	if tiempo_restante <= 0:
		await perder("tiempo")

# -------------------------
# RESET
# -------------------------
# ... (variables anteriores iguales)

# -------------------------
# GANAR (MODIFICADO)
# -------------------------
func ganar() -> void:
	cronometro.stop()
	guardar_seleccion()
	victorias_actuales += 1
	$"../ScreenOverlay/progreso".text=str(victorias_actuales)+"/3"
	if sonido_cartas.playing:
		sonido_cartas.stop()
	sonido_cartas.play()

	animacion.play("esconder_cartas")
	await animacion.animation_finished

	# 🔥 SOLO SI NO ES LA ÚLTIMA
	if victorias_actuales < victorias_necesarias:
		generate_solution()
		if cinematic_node:
			cinematic_node.set_solucion([], tipo_operacion, objetivo)

		if cinematic_node:
			await cinematic_node.notificar_progreso(victorias_actuales, victorias_necesarias)

		await reiniciar_flujo()

	# 🔥 SI ES LA ÚLTIMA → NO PROGRESO
	else:
		await iniciar_fase_final()

# -------------------------
# PERDER (MODIFICADO)
# -------------------------
func perder(tipo := "error") -> void:
	cronometro.stop()

	# ✅ SONIDO DE BARajar SOLO AQUÍ
	if sonido_barajar.playing:
		sonido_barajar.stop()
	sonido_barajar.play()

	animacion.play("barajar_cartas")
	await animacion.animation_finished

	# Nueva solución
	generate_solution()
	if cinematic_node:
		cinematic_node.set_solucion([], tipo_operacion, objetivo)

	# Notificar pérdida
	if cinematic_node:
		await cinematic_node.notificar_perdida(tipo)

	await reiniciar_flujo()
# -------------------------
# INICIO (MODIFICADO)
# -------------------------
func iniciar_puzzle() -> void:
	puzzle_activo = false
	ha_interactuado = false
	resetear_cartas()

	# ❌ SIN sonido aquí
	animacion.play("revelar_cartas")
	await animacion.animation_finished

	mostrar_cartas()

	puzzle_activo = true
	tiempo_restante = tiempo_total
	label_cronometro.text = "Tiempo: %02d" % int(tiempo_restante)

# -------------------------
# REINICIAR FLUJO
# -------------------------
func reiniciar_flujo() -> void:
	await get_tree().create_timer(0.3).timeout
	# Ya no generamos aquí, solo iniciamos lo visual
	await iniciar_puzzle()
	iniciar_tiempo()
# -------------------------
# TIMER
# -------------------------
func iniciar_tiempo() -> void:
	cronometro.start()

# -------------------------
# FASE FINAL
# -------------------------
func iniciar_fase_final() -> void:
	get_node("../CajaFuerte").visible = true
	cronometro.stop()
	puzzle_activo = false
	ocultar_cartas()

	# 🎬 CINEMÁTICA PREVIA
	if cinematic_node:
		await cinematic_node.notificar_previo_final()

	# limpiar
	for child in contenedor_diales.get_children():
		child.queue_free()

	for i in range(secuencia_simbolos.size()):
		var nuevo_dial = dial_scene.instantiate()
		contenedor_diales.add_child(nuevo_dial)
		input_usuario.resize(secuencia_simbolos.size())
		input_usuario[i] = nuevo_dial.get_valor()

		var index = i
		nuevo_dial.valor_cambiado.connect(func(nuevo_nombre):
			input_usuario[index] = nuevo_nombre
		)

	canvas_final.visible = true


func agregar_input(simbolo: String) -> void:
	input_usuario.append(str(simbolo))



# -------------------------
# VISUAL
# -------------------------
func mostrar_cartas():
	for c in cartas_nodos:
		c.visible = true

func ocultar_cartas():
	for c in cartas_nodos:
		c.visible = false

func resetear_cartas() -> void:
	seleccionadas.clear()

	for c in cartas_nodos:
		c.visible = false
		if c.has_method("resetear"):
			c.resetear()


func _on_confirmar_pressed() -> void:
	print("Jugador:", input_usuario)
	print("Correcto:", secuencia_simbolos)

	if input_usuario == secuencia_simbolos:
		print("✅ CÓDIGO CORRECTO")
		canvas_final.visible = false
		await cinematic_node.notificar_final_ganado()
	else:
		print("❌ CÓDIGO INCORRECTO - REINICIANDO TODO")
		canvas_final.visible = false
		
		victorias_actuales = 0
		$"../ScreenOverlay/progreso".text=str(victorias_actuales)+"/3"
		secuencia_simbolos.clear()
		input_usuario.clear()
		
		await cinematic_node.notificar_perdida("codigo")
		await reiniciar_flujo()
func actualizar_seleccion_mando():

	for i in range(cartas_nodos.size()):

		var carta = cartas_nodos[i]

		# CARTA ACTUAL DEL CURSOR
		if i == carta_seleccionada:

			carta.scale = carta.escala_original * 1.15

			# Si NO está seleccionada → brillo blanco
			if not carta.seleccionada:
				carta.modulate = Color(1.2, 1.2, 1.2)

			# Si está seleccionada → mantener amarillo
			else:
				carta.modulate = Color(1.5, 1.5, 0.8)

		# RESTO DE CARTAS
		else:

			carta.scale = carta.escala_original

			# Mantener amarillo si ya fue seleccionada
			if carta.seleccionada:
				carta.modulate = Color(1.5, 1.5, 0.8)

			# Si no está seleccionada → normal
			else:
				carta.modulate = Color.WHITE
