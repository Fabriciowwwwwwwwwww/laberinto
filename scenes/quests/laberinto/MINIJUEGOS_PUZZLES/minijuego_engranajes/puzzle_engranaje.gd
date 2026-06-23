extends Node2D
var gear_actual := 0
@export var num_gears: int = 7
@export var tiempo_total: float = 30.0
var engranaje_seleccionado := 0
var solution: Array[int] = []
var gears: Array = []
var cinematic_node: Node
@onready var sonido_reloj: AudioStreamPlayer2D = $"../sonido_reloj"
@onready var sonido_candado: AudioStreamPlayer2D = $"../sonido_candado"

@onready var cronometro: Timer = $"../Cronometro"
@onready var label_cronometro: Label = $"../ScreenOverlay/CronometroLabel"

var tiempo_restante: float
var puzzle_activo: bool = false
var ha_interactuado: bool = false

# -------------------------
# INIT
# -------------------------
func _ready() -> void:
	sonido_reloj.bus = "SFX"
	sonido_candado.bus = "SFX"
	add_to_group("puzzle")

	cronometro.wait_time = 1.0
	cronometro.timeout.connect(_on_cronometro_tick)

	cinematic_node = get_tree().get_first_node_in_group("cinematica")

	var nodes = get_tree().get_nodes_in_group("engranaje")
	for n in nodes:
		gears.append(n)

	gears.sort_custom(
		func(a,b):
			return int(a.gear_id) < int(b.gear_id)
	)

	seleccionar_engranaje(0)

	# 🔥 GENERAR ANTES DE LA INTRO
	generate_solution()

	if cinematic_node:
		cinematic_node.set_solucion(solution)

	await iniciar_intro()

# -------------------------
# INTRO
# -------------------------
func iniciar_intro() -> void:
	if cinematic_node:
		await cinematic_node.cinematica_terminada

	await iniciar_flujo()

# -------------------------
# FLUJO
# -------------------------
func iniciar_flujo() -> void:
	iniciar_puzzle()
	await get_tree().create_timer(0.2).timeout
	iniciar_tiempo()
	sonido_reloj.play()

# -------------------------
# INPUT
# -------------------------
func _input(event: InputEvent) -> void:

	# =====================
	# CAMBIAR ENGRANAJE
	# =====================

	if event.is_action_pressed("ui_left"):
		seleccionar_engranaje(engranaje_seleccionado - 1)
		return

	if event.is_action_pressed("ui_right"):
		seleccionar_engranaje(engranaje_seleccionado + 1)
		return

	# =====================
	# SI EL PUZZLE ESTÁ BLOQUEADO
	# =====================

	if not puzzle_activo:
		return

	# =====================
	# GIRAR ENGRANAJE
	# =====================

	if event.is_action_pressed("Interact"):

		if gears.is_empty():
			return

		get_tree().call_group("puzzle", "registrar_interaccion")

		gears[engranaje_seleccionado].activar_desde_mando()

		return

	# =====================
	# VALIDAR SOLUCIÓN
	# =====================

	if Input.is_action_just_pressed("ui_accept") \
	or Input.is_action_just_pressed("undo"):

		if not ha_interactuado:
			print("⚠️ Mueve al menos un engranaje")
			return

		await check_solution()

	# =====================
	# MÓVIL
	# =====================

	if event is InputEventScreenTouch and event.pressed:
		pass
func registrar_interaccion() -> void:
	ha_interactuado = true



# -------------------------
# INICIO DEL PUZZLE
# -------------------------
func iniciar_puzzle() -> void:
	puzzle_activo = true
	ha_interactuado = false

	tiempo_restante = tiempo_total
	label_cronometro.text = "Tiempo: %02d" % int(tiempo_restante)

# -------------------------
# GENERAR SOLUCIÓN
# -------------------------
func generate_solution() -> void:
	solution.clear()

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Generar solución inicial
	for i in range(num_gears):
		solution.append(rng.randi_range(0, 1))

	# Evitar demasiados iguales seguidos
	var consecutivos := 1

	for i in range(1, solution.size()):
		if solution[i] == solution[i - 1]:
			consecutivos += 1

			# Si hay 3 iguales seguidos, forzar cambio
			if consecutivos >= 3:
				solution[i] = 1 - solution[i]
				consecutivos = 1
		else:
			consecutivos = 1

	print("Solución generada: ", solution)



# -------------------------
# CHECK
# -------------------------
func check_solution() -> void:
	puzzle_activo = false
	cronometro.stop()

	var correcto := true

	for i in range(gears.size()):
		if gears[i].rotation_state != solution[i]:
			correcto = false
			break

	if correcto:
		await puzzle_solved()
	else:
		await perder()

# -------------------------
# GANAR
# -------------------------
func puzzle_solved() -> void:
	print("🎉 GANASTE")
	sonido_candado.play()

	puzzle_activo = false
	cronometro.stop()

	get_tree().call_group("candado", "abrir_candado")

	# ⏳ ESPERAR animación
	await get_tree().create_timer(1.5).timeout

	if cinematic_node:
		await cinematic_node.notificar_ganador()

# -------------------------
# PERDER
# -------------------------
func perder() -> void:
	sonido_reloj.stop()
	print("❌ FALLASTE")

	puzzle_activo = false
	cronometro.stop()

	for g in gears:
		g.forzar_detener()

	# 🔥 GENERAR NUEVA SOLUCIÓN ANTES DEL DIÁLOGO
	generate_solution()

	if cinematic_node:
		cinematic_node.set_solucion(solution)
		await cinematic_node.notificar_perdida("error")

	await reiniciar_flujo()
# -------------------------
# TIEMPO
# -------------------------
func _on_cronometro_tick() -> void:
	if not puzzle_activo:
		return
	tiempo_restante -= 1
	label_cronometro.text = "Tiempo: %02d" % int(tiempo_restante)
	if tiempo_restante <= 0:
		print("⏰ TIEMPO AGOTADO")
		puzzle_activo = false
		cronometro.stop()
		for g in gears:
			g.forzar_detener()
		generate_solution()
		if cinematic_node:
			cinematic_node.set_solucion(solution)
			await cinematic_node.notificar_perdida("tiempo")
		await reiniciar_flujo()
# -------------------------
# TIMER START
# -------------------------
func iniciar_tiempo() -> void:
	cronometro.start()
func reiniciar_flujo() -> void:

	for g in gears:
		g.reset_total()

	await get_tree().create_timer(0.3).timeout

	# ❌ QUITAR generate_solution()

	iniciar_puzzle()
	iniciar_tiempo()


func _on_texture_button_pressed() -> void:
	if not ha_interactuado:
		print("⚠️ Mueve al menos un engranaje")
		return
	await check_solution()
func seleccionar_engranaje(indice:int):

	if gears.is_empty():
		return

	# Ciclo infinito
	engranaje_seleccionado = wrapi(
		indice,
		0,
		gears.size()
	)

	for i in range(gears.size()):

		var g = gears[i]

		if i == engranaje_seleccionado:

			g.target_scale = g.base_scale * 1.2

			if g.sprite:
				g.sprite.modulate = Color(1.4, 1.4, 1.4)

		else:

			g.target_scale = g.base_scale

			if g.sprite:
				g.sprite.modulate = Color.WHITE

	print("⚙️ Engranaje seleccionado:", engranaje_seleccionado + 1)
