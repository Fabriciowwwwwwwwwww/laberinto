extends Node2D
@onready var canvas_final: CanvasLayer = $"../CajaFuerte"
@onready var contenedor_diales: HBoxContainer = $"../CajaFuerte/HBoxContainer"
var input_usuario: Array = []
var secuencia_simbolos: Array = []
# Diccionario para cargar las imágenes de los símbolos

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
func _ready() -> void:
	add_to_group("puzzle")
	secuencia_simbolos.clear()

	for n in get_tree().get_nodes_in_group("cartas"):
		cartas_nodos.append(n)

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

	# 2. Generar 'a' y 'b' (asegurando que b != a)
	if tipo == 0:
		tipo_operacion = "SUMA"
		a = randi_range(1, 9)
		b = randi_range(1, 9)
		while b == a: # Evita que a y b sean iguales (opcional, pero ayuda a la variedad)
			b = randi_range(1, 9)
		objetivo = a + b
	else:
		tipo_operacion = "MULT"
		a = randi_range(1, 5)
		b = randi_range(1, 5)
		while b == a:
			b = randi_range(1, 5)
		objetivo = a * b

	# Guardamos los dos valores de la solución
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
	if event.is_action_pressed("ui_accept") and puzzle_activo:

		if not ha_interactuado:
			return

		puzzle_activo = false

		ocultar_cartas()

		await get_tree().process_frame
		sonido_cartas.play()
		animacion.play("esconder_cartas")
		await animacion.animation_finished

		await verificar()

# -------------------------
# VERIFICAR
# -------------------------
func verificar() -> void:
	var resultado = 0

	if tipo_operacion == "SUMA":
		for i in seleccionadas:
			resultado += valores_cartas[i]
	else:
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

	animacion.play("barajar_cartas")
	await animacion.animation_finished

	# ✅ 1. GENERAMOS LA SIGUIENTE SOLUCIÓN ANTES DEL DIÁLOGO
	if victorias_actuales < victorias_necesarias:
		generate_solution()
		if cinematic_node:
			cinematic_node.set_solucion([], tipo_operacion, objetivo)

	# ✅ 2. AHORA SÍ NOTIFICAMOS (Ya tiene los datos nuevos)
	if cinematic_node:
		await cinematic_node.notificar_progreso(victorias_actuales, victorias_necesarias)

	if victorias_actuales >= victorias_necesarias:
		await iniciar_fase_final()
	else:
		await reiniciar_flujo()

# -------------------------
# PERDER (MODIFICADO)
# -------------------------
func perder(tipo := "error") -> void:
	cronometro.stop()

	sonido_barajar.play()
	animacion.play("barajar_cartas")
	await animacion.animation_finished

	# ✅ 1. GENERAMOS NUEVA SOLUCIÓN PARA EL REINTENTO
	generate_solution()
	if cinematic_node:
		cinematic_node.set_solucion([], tipo_operacion, objetivo)

	# ✅ 2. NOTIFICAMOS LA PÉRDIDA
	if cinematic_node:
		await cinematic_node.notificar_perdida(tipo)
		# Nota: quitamos el await cinematic_terminada de aquí si ya está en la función notificar

	await reiniciar_flujo()

# -------------------------
# INICIO (MODIFICADO)
# -------------------------
func iniciar_puzzle() -> void:
	puzzle_activo = false
	ha_interactuado = false
	resetear_cartas()

	# ❌ QUITAMOS EL GENERATE_SOLUTION DE AQUÍ
	# Porque ahora lo hacemos en ready, ganar o perder.

	sonido_cartas.play()
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
	cronometro.stop()
	puzzle_activo = false
	ocultar_cartas()
	
	# Limpiar HBoxContainer
	for child in contenedor_diales.get_children():
		child.queue_free()
	
	# Instanciar tantos diales como símbolos haya en la secuencia
	for i in secuencia_simbolos.size():
		var nuevo_dial = dial_scene.instantiate()
		contenedor_diales.add_child(nuevo_dial)
		
		# Forzamos al array a tener el tamaño correcto con el valor inicial del dial
		if input_usuario.size() < secuencia_simbolos.size():
			input_usuario.resize(secuencia_simbolos.size())
		input_usuario[i] = nuevo_dial.get_valor()

		# Conectamos la señal para que actualice el array cuando el jugador toque las flechas
		nuevo_dial.valor_cambiado.connect(func(nuevo_nombre):
			input_usuario[i] = nuevo_nombre
			print("Código actualizado en posición ", i, ": ", nuevo_nombre)
		)

	canvas_final.visible = true
	


func agregar_input(simbolo: String) -> void:
	input_usuario.append(str(simbolo))

	if input_usuario.size() == secuencia_simbolos.size():
		await verificar_codigo_final()

func verificar_codigo_final() -> void:
	print("Jugador:", input_usuario)
	print("Correcto:", secuencia_simbolos)

	if input_usuario == secuencia_simbolos:
		await cinematic_node.notificar_ganador()
	else:
		input_usuario.clear()
		await cinematic_node.notificar_perdida("codigo")
		await iniciar_fase_final()

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
	if str(input_usuario) == str(secuencia_simbolos):
		print("✅ CÓDIGO CORRECTO")
		canvas_final.visible = false
		await cinematic_node.notificar_ganador()
	else:
		print("❌ CÓDIGO INCORRECTO - REINICIANDO TODO")
		canvas_final.visible = false
		
		# Reset total estilo Resident Evil
		victorias_actuales = 0
		secuencia_simbolos.clear()
		input_usuario.clear()
		
		await cinematic_node.notificar_perdida("codigo")
		await reiniciar_flujo()
