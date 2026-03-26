extends Node2D

@export var tiempo_total: float = 15.0
@export var victorias_necesarias: int = 3

var cinematic_node: Node
var cartas_nodos: Array = []

@onready var cronometro: Timer = $"../Cronometro"
@onready var label_cronometro: Label = $"../ScreenOverlay/CronometroLabel"
@onready var animacion: AnimatedSprite2D = $animacion_cartas

# LABELS
@onready var label_carta1_arriba: Label = $"carta/label_carta_1_parte de arriba"
@onready var label_carta1_abajo: Label = $"carta/label_carta_1_parte de abajo"

@onready var label_carta2_arriba: Label = $"carta2/label_carta_2_parte de arriba"
@onready var label_carta2_abajo: Label = $"carta2/label_carta_2_parte de abajo"

@onready var label_carta3_arriba: Label = $"carta3/label_carta_3_parte de arriba"
@onready var label_carta3_abajo: Label = $"carta3/label_carta_3_parte de abajo"

@onready var label_carta4_arriba: Label = $"carta4/label_carta_4_parte de arriba"
@onready var label_carta4_abajo: Label = $"carta4/label_carta_4_parte de abajo"

# LOGICA
var tiempo_restante: float
var puzzle_activo: bool = false
var ha_interactuado: bool = false

var valores_cartas: Array = []
var seleccionadas: Array = []

var objetivo: int = 0
var tipo_operacion: String = ""
var solution: Array = []

var victorias_actuales: int = 0

# -------------------------
# READY
# -------------------------
func _ready():
	add_to_group("puzzle")

	for n in get_tree().get_nodes_in_group("cartas"):
		cartas_nodos.append(n)

	resetear_cartas()

	cronometro.wait_time = 1.0
	cronometro.timeout.connect(_on_cronometro_tick)

	cinematic_node = get_tree().get_first_node_in_group("cinematica")

	await iniciar_intro()

# -------------------------
# RESET
# -------------------------
func resetear_cartas():
	seleccionadas.clear()

	for c in cartas_nodos:
		c.visible = false
		if c.has_method("resetear"):
			c.resetear()

# -------------------------
# FLUJO
# -------------------------
func iniciar_intro():
	if cinematic_node:
		await cinematic_node.cinematica_terminada
	
	await iniciar_flujo()

func iniciar_flujo():
	iniciar_puzzle()
	await get_tree().create_timer(0.2).timeout
	iniciar_tiempo()

# -------------------------
# INICIO
# -------------------------
func iniciar_puzzle():
	puzzle_activo = false
	ha_interactuado = false

	resetear_cartas()
	generar_cartas()
	generate_solution()

	if cinematic_node:
		cinematic_node.set_solucion(solution)

	animacion.play("revelar_cartas")
	await animacion.animation_finished

	mostrar_cartas()

	puzzle_activo = true

	tiempo_restante = tiempo_total
	label_cronometro.text = "Tiempo: %02d" % int(tiempo_restante)

# -------------------------
# CARTAS
# -------------------------
func generar_cartas():
	valores_cartas.clear()

	for i in range(4):
		valores_cartas.append(randi_range(1, 10))

	label_carta1_arriba.text = str(valores_cartas[0])
	label_carta1_abajo.text = str(valores_cartas[0])

	label_carta2_arriba.text = str(valores_cartas[1])
	label_carta2_abajo.text = str(valores_cartas[1])

	label_carta3_arriba.text = str(valores_cartas[2])
	label_carta3_abajo.text = str(valores_cartas[2])

	label_carta4_arriba.text = str(valores_cartas[3])
	label_carta4_abajo.text = str(valores_cartas[3])

func mostrar_cartas():
	for c in cartas_nodos:
		c.visible = true

func ocultar_cartas():
	for c in cartas_nodos:
		c.visible = false

# -------------------------
# SOLUCION (SUMA / MULT)
# -------------------------
func generate_solution():
	solution.clear()

	var i = randi_range(0, 3)
	var j = randi_range(0, 3)

	while j == i:
		j = randi_range(0, 3)

	var tipo = randi_range(0, 1)

	if tipo == 0:
		tipo_operacion = "SUMA"
		objetivo = valores_cartas[i] + valores_cartas[j]
	else:
		tipo_operacion = "MULT"
		objetivo = valores_cartas[i] * valores_cartas[j]

	solution = [i, j]

	print("🎯 OBJETIVO:", tipo_operacion, objetivo)

# -------------------------
# INPUT
# -------------------------
func seleccionar_carta(index):
	if not puzzle_activo:
		return

	if index in seleccionadas:
		seleccionadas.erase(index)
	else:
		seleccionadas.append(index)

	ha_interactuado = true

	print("Seleccionadas:", seleccionadas)

# -------------------------
# ENTER
# -------------------------
func _input(event):
	if event.is_action_pressed("ui_accept") and puzzle_activo:

		if not ha_interactuado:
			return

		puzzle_activo = false

		# 🔥 ocultar instantáneo antes de animación
		ocultar_cartas()

		await get_tree().process_frame

		animacion.play("esconder_cartas")
		await animacion.animation_finished

		await verificar_suma()

# -------------------------
# VERIFICAR
# -------------------------
func verificar_suma():
	var resultado = 0

	if tipo_operacion == "SUMA":
		for i in seleccionadas:
			resultado += valores_cartas[i]

	elif tipo_operacion == "MULT":
		resultado = 1
		for i in seleccionadas:
			resultado *= valores_cartas[i]

	print("Resultado:", resultado)

	if resultado == objetivo:
		await ganar()
	else:
		await perder("error")

# -------------------------
# GANAR
# -------------------------
func ganar():
	print("✅ GANASTE")

	cronometro.stop()
	victorias_actuales += 1

	# animación SIEMPRE
	animacion.play("barajar_cartas")
	await animacion.animation_finished

	if cinematic_node:
		await cinematic_node.notificar_progreso(victorias_actuales, victorias_necesarias)

	if victorias_actuales >= victorias_necesarias:
		if cinematic_node:
			await cinematic_node.notificar_ganador()
	else:
		await reiniciar_flujo()

# -------------------------
# PERDER
# -------------------------
func perder(tipo := "error"):
	print("❌ FALLASTE")

	cronometro.stop()

	animacion.play("barajar_cartas")
	await animacion.animation_finished

	if cinematic_node:
		await cinematic_node.notificar_perdida(tipo)

	await reiniciar_flujo()

# -------------------------
# TIEMPO
# -------------------------
func _on_cronometro_tick():
	if not puzzle_activo:
		return

	tiempo_restante -= 1
	label_cronometro.text = "Tiempo: %02d" % int(tiempo_restante)

	if tiempo_restante <= 0:
		await perder("tiempo")

# -------------------------
# RESET
# -------------------------
func reiniciar_flujo():
	puzzle_activo = false
	await get_tree().create_timer(0.3).timeout
	iniciar_puzzle()
	iniciar_tiempo()

# -------------------------
# TIMER
# -------------------------
func iniciar_tiempo():
	cronometro.start()
