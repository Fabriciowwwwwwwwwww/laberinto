extends Node2D

# =========================
# REFERENCIAS
# =========================

var escena_base: PackedScene = null
@onready var botones_color = $CanvasLayer/BottomUI/SelectorGrupos.get_children()
@onready var zonas_reales = $OnTheGround/ZonaSistema/Zonas
@onready var label_grupo = $CanvasLayer/TopUI/TituloGrupo
var modo_sliders := false
var slider_actual := 0

var sliders := []
@onready var cinematica = $cinematica_colores

# UI
@onready var label_resultado = %ResultadoLabel
@onready var cronometrolabel = %CronometroLabel

# sliders RGB
@onready var slider_r = $CanvasLayer/BottomUI/SlidersRGB/SliderR
@onready var slider_g = $CanvasLayer/BottomUI/SlidersRGB/SliderG
@onready var slider_b = $CanvasLayer/BottomUI/SlidersRGB/SliderB

@onready var boton_validar = $CanvasLayer/BottomUI/BotonValidar

# preview color
@export_range(0, 100)
var porcentaje_minimo := 60.0

@export_range(0.0, 1.0)
var precision_color := 1.0

# contenedores visuales
@onready var contenedor_juego = $CanvasLayer/juego/ContenedorJuego
@onready var contenedor_referencia = $CanvasLayer/referencia/ContenedorReferencia

# =========================
# EXPORTS
# =========================

@export var escenas_solucion: Array[PackedScene]

# =========================
# VARIABLES
# =========================

var solucion := {}
var escena_actual: Node = null
var puzzle_visual: Node = null
var intro_terminada := false
var estado_actual := {}
var colores_guardados := {}

# =========================
# LABELS RGB
# =========================

@onready var label_r = $CanvasLayer/BottomUI/SlidersRGB/SliderR/LabelR
@onready var label_g = $"CanvasLayer/BottomUI/SlidersRGB/SliderG/Label G"
@onready var label_b = $"CanvasLayer/BottomUI/SlidersRGB/SliderB/Label B"

# color/grupo actualmente seleccionado
var grupo_actual := 0
var color_actual := Color.WHITE

# zonas del puzzle visual
var zonas_juego := []

# =========================
# CRONÓMETRO
# =========================

@export var tiempo_limite := 40.0

var tiempo_actual := 0.0
var juego_terminado := false

# =========================
# READY
# =========================

func _ready():
	sliders = [slider_r, slider_g, slider_b]
	configurar_mando()
	set_process(true)
	print("🟢 Puzzle iniciado")
	inicializar_sliders()
	conectar_botones()
	boton_validar.pressed.connect(validar)
	label_grupo.text = "COLOR 1"
	iniciar_ronda()

# =========================
# SLIDERS
# =========================

func inicializar_sliders():
	# ⚠️ Sliders sin foco del sistema → se controlan solo manualmente
	slider_r.focus_mode = Control.FOCUS_NONE
	slider_g.focus_mode = Control.FOCUS_NONE
	slider_b.focus_mode = Control.FOCUS_NONE

	for s in [slider_r, slider_g, slider_b]:
		s.min_value = 0
		s.max_value = 1
		s.step = 0.01
		s.value_changed.connect(_on_slider_changed)

	actualizar_labels_rgb()

# =========================
# CONFIGURAR MANDO
# =========================

func configurar_mando():
	for boton in botones_color:
		boton.texture_focused = boton.texture_hover
		boton.focus_mode = Control.FOCUS_ALL

	boton_validar.focus_mode = Control.FOCUS_ALL
	boton_validar.texture_focused = boton_validar.texture_hover

	# ⚠️ Sliders SIN foco del sistema → solo se controlan manualmente
	slider_r.focus_mode = Control.FOCUS_NONE
	slider_g.focus_mode = Control.FOCUS_NONE
	slider_b.focus_mode = Control.FOCUS_NONE

	# =====================
	# BOTONES DE COLOR
	# =====================

	for i in range(botones_color.size()):
		var actual = botones_color[i]

		if i > 0:
			actual.focus_neighbor_left = actual.get_path_to(botones_color[i - 1])

		if i < botones_color.size() - 1:
			actual.focus_neighbor_right = actual.get_path_to(botones_color[i + 1])

		# ↓ bajar al botón validar (NO a los sliders)
		actual.focus_neighbor_bottom = actual.get_path_to(boton_validar)

	# =====================
	# VALIDAR
	# =====================

	# ↑ subir de validar a los botones de color
	boton_validar.focus_neighbor_top = boton_validar.get_path_to(botones_color[0])
	boton_validar.focus_neighbor_left = boton_validar.get_path_to(botones_color[0])

# =========================
# INPUT
# =========================

func _unhandled_input(event):

	# =====================
	# MODO SLIDERS
	# =====================

	if modo_sliders:

		if event.is_action_pressed("ui_down"):
			slider_actual = min(slider_actual + 1, sliders.size() - 1)
			actualizar_slider_seleccionado()
			print("Slider:", slider_actual)

		elif event.is_action_pressed("ui_up"):
			slider_actual = max(slider_actual - 1, 0)
			actualizar_slider_seleccionado()
			print("Slider:", slider_actual)

		elif event.is_action_pressed("ui_cancel"):

			print("Volviendo a botones")

			modo_sliders = false

			for s in sliders:
				s.modulate = Color.WHITE

			await get_tree().process_frame

			if grupo_actual < botones_color.size():
				botones_color[grupo_actual].grab_focus()

		get_viewport().set_input_as_handled()
		return

	# =====================
	# MODO BOTONES
	# =====================

	if event.is_action_pressed("Interact"):

		var control = get_viewport().gui_get_focus_owner()

		if control == boton_validar:
			validar()
			return

		if control in botones_color:

			var id = botones_color.find(control)

			if id != -1:
				seleccionar_grupo(id)

			print("Entrando a sliders")

			modo_sliders = true
			slider_actual = 0

			actualizar_slider_seleccionado()

			control.release_focus()

			get_viewport().set_input_as_handled()
			return
func iniciar_ronda():

	print("🔄 iniciar_ronda()")

	if escena_actual:
		escena_actual.queue_free()
		escena_actual = null

	if puzzle_visual:
		puzzle_visual.queue_free()
		puzzle_visual = null

	await get_tree().process_frame

	intro_terminada = false

	modo_sliders = false
	slider_actual = 0

	colores_guardados.clear()
	estado_actual.clear()

	tiempo_actual = tiempo_limite
	juego_terminado = false

	label_resultado.text = "0.0%"

	actualizar_cronometro()

	limpiar_zonas_reales()

	slider_r.value = 1
	slider_g.value = 1
	slider_b.value = 1
	for s in sliders:
		s.modulate = Color.WHITE
	actualizar_labels_rgb()

	seleccionar_escena_random()

	escena_actual.generar_colores()
	solucion = escena_actual.get_solucion()

	cinematica.set_puzzle(self)

	await crear_referencia()
	await crear_puzzle_visual()

	$CanvasLayer/juego.visible = false
	$CanvasLayer/BottomUI.visible = false

	$CanvasLayer/referencia.visible = true
	$CanvasLayer/referencia.position = Vector2(650,120)

	print("⏳ Esperando cinematica")

	await cinematica.cinematica_terminada

	print("✅ Cinematica terminada")

	intro_terminada = true

	await mostrar_juego()
func mostrar_juego():
	$CanvasLayer/juego.visible = true
	$CanvasLayer/BottomUI.visible = true
	$CanvasLayer/referencia.visible = true

	$CanvasLayer/juego.position = Vector2(180, 180)
	$CanvasLayer/referencia.position = Vector2(980, 180)

	await get_tree().process_frame

	if botones_color.size() > 0:
		botones_color[0].grab_focus()

# =========================
# PROCESS
# =========================

func _process(delta):

	# =====================
	# CONTROL FLUIDO SLIDERS
	# =====================

	if modo_sliders:

		var velocidad := 1.2

		if Input.is_action_pressed("ui_left"):
			sliders[slider_actual].value -= velocidad * delta

		if Input.is_action_pressed("ui_right"):
			sliders[slider_actual].value += velocidad * delta

		return

	# =====================
	# CRONÓMETRO
	# =====================

	if juego_terminado:
		return

	if not intro_terminada:
		return

	tiempo_actual -= delta

	if tiempo_actual <= 0:
		tiempo_actual = 0
		actualizar_cronometro()
		validar()
		return

	actualizar_cronometro()
# =========================
# ESCENA RANDOM
# =========================

func seleccionar_escena_random():
	if escenas_solucion.is_empty():
		push_error("❌ No hay escenas solución")
		return

	escena_base = escenas_solucion.pick_random()
	escena_actual = escena_base.instantiate()
	print("🎲 Escena elegida:", escena_base.resource_path)

# =========================
# REFERENCIA (CORRECTA)
# =========================

func crear_referencia():
	for c in contenedor_referencia.get_children():
		c.queue_free()

	await get_tree().process_frame

	var referencia = escena_actual

	if referencia.get_parent():
		referencia.get_parent().remove_child(referencia)

	contenedor_referencia.add_child(referencia)
	referencia.position = Vector2.ZERO
	print("🖼️ Referencia coloreada creada")

# =========================
# PUZZLE VISUAL (GRIS)
# =========================

func crear_puzzle_visual():

	for c in contenedor_juego.get_children():
		c.queue_free()

	await get_tree().process_frame

	puzzle_visual = escena_base.instantiate()
	contenedor_juego.add_child(puzzle_visual)
	puzzle_visual.position = Vector2.ZERO

	zonas_juego.clear()

	var zonas = puzzle_visual.get_node("Zonas").get_children()

	for zona in zonas:
		zona.texture = null

		if zona.has_method("resetear"):
			zona.resetear()

		zonas_juego.append(zona)

		print(
			zona.name,
			" color=", zona.color,
			" modulate=", zona.modulate,
			" texture=", zona.texture
		)

		zonas_juego.append(zona)

	print("🎮 Puzzle gris creado")
	var conteo := {}

	for zona in zonas_juego:

		if "id_color" in zona:

			if not conteo.has(zona.id_color):
				conteo[zona.id_color] = 0

			conteo[zona.id_color] += 1

	print("CONTEO IDS:")
	print(conteo)
# =========================
# BOTONES
# =========================

func conectar_botones():
	var botones = $CanvasLayer/BottomUI/SelectorGrupos.get_children()

	for i in range(botones.size()):
		var boton = botones[i]
		boton.pressed.connect(
			func():
				seleccionar_grupo(i)
		)

# =========================
# SELECCIONAR GRUPO
# =========================

func seleccionar_grupo(id):
	# guardar color actual antes de cambiar
	colores_guardados[grupo_actual] = Color(
		slider_r.value,
		slider_g.value,
		slider_b.value,
		1
	)

	grupo_actual = id
	print("🎨 Grupo seleccionado:", id)

	label_grupo.text = "COLOR " + str(id + 1)

	# si ya tenía color guardado → cargarlo
	if colores_guardados.has(id):
		var c = colores_guardados[id]
		slider_r.value = c.r
		slider_g.value = c.g
		slider_b.value = c.b
		color_actual = c
	else:
		slider_r.value = 1
		slider_g.value = 1
		slider_b.value = 1
		color_actual = Color.WHITE

# =========================
# CAMBIO COLOR
# =========================

func _on_slider_changed(_value):
	color_actual = Color(
		slider_r.value,
		slider_g.value,
		slider_b.value,
		1
	)
	actualizar_labels_rgb()
	pintar_grupo_actual()

# =========================
# ACTUALIZAR LABELS RGB
# =========================

func actualizar_labels_rgb():
	var r = int(slider_r.value * 255)
	var g = int(slider_g.value * 255)
	var b = int(slider_b.value * 255)

	label_r.text = "R: " + str(r)
	label_g.text = "G: " + str(g)
	label_b.text = "B: " + str(b)

# =========================
# PINTAR
# =========================

func pintar_grupo_actual():
	print("\n🖌️ Pintando grupo:", grupo_actual)

	var encontradas := 0

	for zona in zonas_juego:
		if not ("id_color" in zona):
			continue

		if zona.id_color == grupo_actual:
			encontradas += 1
			if zona.has_method("aplicar_color"):
				zona.aplicar_color(color_actual)

	print("🎯 Zonas pintadas:", encontradas)
	estado_actual[grupo_actual] = color_actual

# =========================
# VALIDAR
# =========================

func validar():

	if juego_terminado:
		return

	juego_terminado = true

	var porcentaje_total := 0.0
	var cantidad := solucion.size()

	if cantidad <= 0:
		return

	for id in solucion.keys():

		if not estado_actual.has(id):
			continue

		var color_jugador = estado_actual[id]
		var color_real = solucion[id]

		var precision = calcular_precision_color(
			color_jugador,
			color_real
		)

		porcentaje_total += precision

	var promedio = porcentaje_total / cantidad
	var porcentaje_final = round(promedio * 100)

	label_resultado.text = str(porcentaje_final) + "%"

	print("🎯 Precisión:", porcentaje_final, "%")

	if porcentaje_final >= porcentaje_minimo:

		label_resultado.text += " ✅"

		await get_tree().create_timer(2.0).timeout

		await victoria()

	else:

		label_resultado.text += " ❌"

		await get_tree().create_timer(2.0).timeout

		print("ANTES DEL DIALOGO DERROTA")

		await cinematica.ejecutar_derrota()

		print("DESPUES DEL DIALOGO DERROTA")

		await reiniciar_ronda()
# =========================
# PRECISIÓN COLOR
# =========================

func calcular_precision_color(a: Color, b: Color):
	var dr = abs(a.r - b.r)
	var dg = abs(a.g - b.g)
	var db = abs(a.b - b.b)

	var diferencia = (dr + dg + db) / 3.0
	var precision = 1.0 - diferencia
	precision *= precision_color

	return clamp(precision, 0.0, 1.0)

# =========================
# COMPARAR COLORES
# =========================

func colores_similares(a: Color, b: Color, tolerancia := 0.18):
	return (
		abs(a.r - b.r) < tolerancia
		and abs(a.g - b.g) < tolerancia
		and abs(a.b - b.b) < tolerancia
	)

# =========================
# LIMPIAR
# =========================

func limpiar_zonas_reales():
	for zona in zonas_reales.get_children():
		if zona.has_method("resetear"):
			zona.resetear()

# =========================
# DERROTA
# =========================

func derrota():
	print("💀 DERROTA")
	label_resultado.text = "❌ Fallaste"
	await cinematica.ejecutar_derrota()
	iniciar_ronda()

# =========================
# VICTORIA
# =========================

func victoria():
	print("🏆 VICTORIA")
	await cinematica.ejecutar_victoria()

# =========================
# CRONÓMETRO UI
# =========================

func actualizar_cronometro():
	var segundos = int(ceil(tiempo_actual))
	cronometrolabel.text = str(segundos)

# =========================
# COMPATIBILIDAD
# =========================

func get_escena_solucion():
	return escena_actual

func ocultar_cronometro():
	pass

func mostrar_cronometro():
	pass
func actualizar_slider_seleccionado():

	for i in range(sliders.size()):

		if i == slider_actual:
			sliders[i].modulate = Color.WHITE
		else:
			sliders[i].modulate = Color(0.7, 0.7, 0.7, 1)
func reiniciar_ronda():

	print("🔄 REINICIANDO")

	intro_terminada = false

	modo_sliders = false
	slider_actual = 0

	colores_guardados.clear()
	estado_actual.clear()

	tiempo_actual = tiempo_limite
	juego_terminado = false

	label_resultado.text = "0.0%"

	actualizar_cronometro()

	limpiar_zonas_reales()

	slider_r.value = 1
	slider_g.value = 1
	slider_b.value = 1

	actualizar_labels_rgb()

	seleccionar_escena_random()

	escena_actual.generar_colores()
	solucion = escena_actual.get_solucion()

	await crear_referencia()
	await crear_puzzle_visual()

	# Mostrar todo directamente
	await mostrar_juego()

	intro_terminada = true
