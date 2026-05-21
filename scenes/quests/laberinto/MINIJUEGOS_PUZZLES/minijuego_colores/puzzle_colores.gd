extends Node2D

# =========================
# REFERENCIAS
# =========================

var escena_base: PackedScene = null

@onready var zonas_reales = $OnTheGround/ZonaSistema/Zonas
@onready var label_grupo = $CanvasLayer/TopUI/TituloGrupo

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
@export_range(0,100)
var porcentaje_minimo := 60.0

@export_range(0.0,1.0)
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

@export var tiempo_limite := 60.0

var tiempo_actual := 0.0
var juego_terminado := false

# =========================
# READY
# =========================

# =========================
# READY
# =========================
# =========================
# SLIDERS
# =========================

func inicializar_sliders():

	for s in [slider_r, slider_g, slider_b]:

		s.min_value = 0
		s.max_value = 1
		s.step = 0.01

		s.value_changed.connect(_on_slider_changed)

	actualizar_labels_rgb()
func _ready():

	set_process(true)

	print("🟢 Puzzle iniciado")

	inicializar_sliders()

	conectar_botones()

	boton_validar.pressed.connect(validar)

	label_grupo.text = "COLOR 1"

	iniciar_ronda()

# =========================
# RONDA
# =========================

func mostrar_juego():

	# mostrar todo
	$CanvasLayer/juego.visible = true
	$CanvasLayer/BottomUI.visible = true
	$CanvasLayer/referencia.visible = true

	# =====================
	# IZQUIERDA = GRIS
	# =====================

	$CanvasLayer/juego.position = Vector2(180, 180)

	# =====================
	# DERECHA = REFERENCIA
	# =====================

	$CanvasLayer/referencia.position = Vector2(980, 180)

# =========================
# RONDA
# =========================

func iniciar_ronda():

	print("\n🔄 NUEVA RONDA")

	colores_guardados.clear()
	estado_actual.clear()

	tiempo_actual = tiempo_limite
	juego_terminado = false

	# reset label resultado
	label_resultado.text = "0.0%"

	actualizar_cronometro()

	limpiar_zonas_reales()

	# reset sliders
	slider_r.value = 1
	slider_g.value = 1
	slider_b.value = 1

	actualizar_labels_rgb()

	# ======================
	# ESCENA RANDOM
	# ======================

	seleccionar_escena_random()

	# ======================
	# GENERAR COLORES
	# ======================

	escena_actual.generar_colores()

	solucion = escena_actual.get_solucion()

	# ======================
	# CONECTAR CINEMÁTICA
	# ======================

	cinematica.set_puzzle(self)

	# ======================
	# OCULTAR TODO GAMEPLAY
	# ======================

	$CanvasLayer/juego.visible = false
	$CanvasLayer/BottomUI.visible = false

	# ======================
	# CREAR SOLO REFERENCIA
	# ======================

	crear_referencia()

	# SOLO referencia visible
	$CanvasLayer/referencia.visible = true

	# centrada
	$CanvasLayer/referencia.position = Vector2(650, 120)

	# ======================
	# INTRO
	# ======================

	await cinematica.ejecutar_secuencia_intro()

	# ======================
	# AHORA SÍ CREAR JUEGO
	# ======================

	crear_puzzle_visual()

	# ======================
	# MOSTRAR GAMEPLAY
	# ======================

	mostrar_juego()

func _process(delta):

	if juego_terminado:
		return

	tiempo_actual -= delta

	if tiempo_actual <= 0:

		tiempo_actual = 0

		actualizar_cronometro()

		# validar automáticamente
		validar()

		return

	actualizar_cronometro()

func _input(event):

	if event.is_action_pressed("ui_accept"):
		validar()

func seleccionar_escena_random():

	if escenas_solucion.is_empty():
		push_error("❌ No hay escenas solución")
		return

	escena_base = escenas_solucion.pick_random()

	# 🎨 ESCENA COLOREADA
	escena_actual = escena_base.instantiate()

	print("🎲 Escena elegida:", escena_base.resource_path)

# =========================
# REFERENCIA (CORRECTA)
# =========================

func crear_referencia():

	# limpiar referencia anterior
	for c in contenedor_referencia.get_children():
		c.queue_free()

	await get_tree().process_frame

	# 🔥 usar escena YA coloreada
	var referencia = escena_actual

	# quitar padre anterior si tiene
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

	# 🔥 NUEVA INSTANCIA LIMPIA
	puzzle_visual = escena_base.instantiate()

	contenedor_juego.add_child(puzzle_visual)

	puzzle_visual.position = Vector2.ZERO

	zonas_juego.clear()

	var zonas = puzzle_visual.get_node("Zonas").get_children()

	for zona in zonas:

		if zona.has_method("resetear"):
			zona.resetear()

		zonas_juego.append(zona)

	print("🎮 Puzzle gris creado")

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

	# actualizar texto
	label_grupo.text = "COLOR " + str(id + 1)

	# si ya tenía color guardado → cargarlo
	if colores_guardados.has(id):

		var c = colores_guardados[id]

		slider_r.value = c.r
		slider_g.value = c.g
		slider_b.value = c.b

		color_actual = c

	else:

		# valores por defecto
		slider_r.value = 1
		slider_g.value = 1
		slider_b.value = 1

		color_actual = Color.WHITE

# =========================
# SLIDERS
# =========================



# =========================
# CAMBIO COLOR
# =========================

func _on_slider_changed(value):

	color_actual = Color(
		slider_r.value,
		slider_g.value,
		slider_b.value,
		1
	)

	actualizar_labels_rgb()

	pintar_grupo_actual()

# =========================
# PINTAR
# =========================
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

	# =========================
	# SI GANA
	# =========================

	if porcentaje_final >= porcentaje_minimo:

		label_resultado.text += " ✅"

		await get_tree().create_timer(2.0).timeout

		victoria()

	# =========================
	# SI PIERDE
	# =========================

	else:

		label_resultado.text += " ❌"

		await get_tree().create_timer(2.0).timeout

		await cinematica.ejecutar_derrota()

		iniciar_ronda()

# =========================
# PRECISIÓN COLOR
# =========================

func calcular_precision_color(a: Color, b: Color):

	# distancia RGB
	var dr = abs(a.r - b.r)
	var dg = abs(a.g - b.g)
	var db = abs(a.b - b.b)

	# diferencia total
	var diferencia = (dr + dg + db) / 3.0

	# convertir a precisión
	var precision = 1.0 - diferencia

	# multiplicador precisión
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
