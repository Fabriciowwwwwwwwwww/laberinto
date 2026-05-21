extends Node2D

# =====================================================
# MINIJUEGO RELOJ VICTORIANO
# =====================================================

@onready var aguja = $AgujaPivot
@onready var zona_objetivo = $ZonaObjetivo

@onready var label_hora = $CanvasLayer/PanelIzquierdo/LabelHoraObjetivo
@onready var label_tiempo = $CanvasLayer/PanelIzquierdo/LabelTiempo
@onready var label_instrucciones = $CanvasLayer/PanelIzquierdo/LabelInstrucciones

@onready var barra_precision = $CanvasLayer/PanelDerecho/BarraPrecision
@onready var label_precision = $CanvasLayer/PanelDerecho/LabelPrecision
@onready var label_resultado = $CanvasLayer/PanelDerecho/LabelResultado

@onready var boton_detener = $CanvasLayer/BotonDetener

@onready var timer = $Timer
@onready var cinematica = $cinematica

# =====================================================
# CONFIG
# =====================================================

@export var velocidad_min := 260.0
@export var velocidad_max := 420.0

# MÁS PEQUEÑA
@export var rango_permitido := 10.0

@export var radio_zona := 230.0

# =====================================================
# VARIABLES
# =====================================================

var velocidad_rotacion := 300.0
var rotacion_actual := 0.0

var hora_objetivo := 3
var angulo_objetivo := 0.0

var juego_terminado := false
var puede_jugar := false

var tiempo_restante := 15

# =====================================================
# READY
# =====================================================

func _ready():

	randomize()

	iniciar_ui()

	boton_detener.pressed.connect(
		detener_reloj
	)

	iniciar_nueva_ronda()

# =====================================================
# NUEVA RONDA
# =====================================================

func iniciar_nueva_ronda():

	generar_hora()

	iniciar_minijuego()

# =====================================================
# UI
# =====================================================

func iniciar_ui():

	label_instrucciones.text = (
		"DETÉN LA AGUJA\n"
		+ "EN LA ZONA ROJA"
	)

	label_resultado.text = ""

	label_precision.text = "PRECISIÓN"

	barra_precision.max_value = 100
	barra_precision.value = 0

	boton_detener.text = "DETENER"

# =====================================================
# INICIAR
# =====================================================

func iniciar_minijuego():

	puede_jugar = true
	juego_terminado = false

	rotacion_actual = randf_range(0, 360)

	# NUEVA VELOCIDAD
	velocidad_rotacion = randf_range(
		velocidad_min,
		velocidad_max
	)

	tiempo_restante = 15

	label_tiempo.text = (
		"TIEMPO: "
		+ str(tiempo_restante)
	)

	label_tiempo.modulate = Color.WHITE

	label_resultado.text = ""

	barra_precision.value = 0

	timer.wait_time = 1.0
	timer.start()

# =====================================================
# GENERAR HORA
# =====================================================

# =====================================================
# GENERAR HORA
# =====================================================

func generar_hora():
	
	# hora aleatoria
	hora_objetivo = randi_range(1, 12)

	# texto UI
	label_hora.text = (
		"OBJETIVO:\n%02d:00"
		% hora_objetivo
	)

	# =================================================
	# ÁNGULO REAL DEL RELOJ
	# =================================================
	#
	# 12 = -90
	# 3  = 0
	# 6  = 90
	# 9  = 180
	#
	# la aguja visual apunta hacia arriba
	#
	# por eso restamos 90
	#
	# =================================================

	angulo_objetivo = (
		((hora_objetivo % 12) * 30) - 90
	)

	angulo_objetivo = wrapf(
		angulo_objetivo,
		0,
		360
)
	# =================================================
	# PASAR SOLUCIÓN REAL
	# =================================================

	cinematica.set_solucion(
		hora_objetivo
	)

	# =================================================
	# CREAR ZONA VISUAL
	# =================================================

	crear_zona_objetivo()

	print(
		"HORA:",
		hora_objetivo,
		" | ANGULO:",
		angulo_objetivo
	)
# =====================================================
# CREAR ZONA
# =====================================================

func crear_zona_objetivo():

	var inicio = deg_to_rad(
		angulo_objetivo
		- rango_permitido
	)

	var fin = deg_to_rad(
		angulo_objetivo
		+ rango_permitido
	)

	var puntos = PackedVector2Array()

	puntos.append(Vector2.ZERO)

	for i in range(40):

		var t = float(i) / 39.0

		var angulo = lerp(
			inicio,
			fin,
			t
		)

		var punto = Vector2(
			cos(angulo),
			sin(angulo)
		) * radio_zona

		puntos.append(punto)

	zona_objetivo.polygon = puntos

	zona_objetivo.color = Color(
		0.8,
		0,
		0,
		0.85
	)

# =====================================================
# PROCESS
# =====================================================

func _process(delta):

	if !puede_jugar:
		return

	if juego_terminado:
		return

	# =================================================
	# ROTACIÓN
	# =================================================

	rotacion_actual += (
		velocidad_rotacion * delta
	)

	rotacion_actual = wrapf(
		rotacion_actual,
		0,
		360
	)

	# =================================================
	# APLICAR
	# =================================================

	aguja.rotation_degrees = (
		rotacion_actual
	)

	# vibración
	aguja.scale = Vector2.ONE * (
		1.0 +
		sin(
			Time.get_ticks_msec()
			* 0.01
		) * 0.01
	)

	# respirar
	zona_objetivo.scale = (
		Vector2.ONE * (
			1.0 +
			sin(
				Time.get_ticks_msec()
				* 0.004
			) * 0.03
		)
	)

	# pulsación
	zona_objetivo.modulate.a = (
		0.6 +
		sin(
			Time.get_ticks_msec()
			* 0.004
		) * 0.2
	)

	# ENTER / SPACE
	if Input.is_action_just_pressed(
		"ui_accept"
	):

		detener_reloj()
func reiniciar():

	juego_terminado = false
	puede_jugar = false

	timer.stop()

	await get_tree().process_frame

	iniciar_nueva_ronda()
# =====================================================
# DETENER
# =====================================================

# =====================================================
# DETENER
# =====================================================
func detener_reloj():

	if juego_terminado:
		return

	juego_terminado = true
	puede_jugar = false

	timer.stop()

	# =================================================
	# ÁNGULO REAL
	# =================================================

	var angulo_aguja = rotacion_actual

	# =================================================
	# DIFERENCIA
	# =================================================

	var diferencia = abs(
		wrapf(
			angulo_aguja
			- angulo_objetivo,
			-180,
			180
		)
	)

	print("OBJ:", angulo_objetivo)
	print("AGUJA:", angulo_aguja)
	print("DIF:", diferencia)

	# =================================================
	# PRECISIÓN
	# =================================================

	var precision = clamp(
		100.0 - (
			(diferencia
			/ rango_permitido)
			* 100.0
		),
		0.0,
		100.0
	)

	barra_precision.value = precision

	label_precision.text = (
		"PRECISIÓN: %d%%"
		% precision
	)

	# =================================================
	# GANAR
	# =================================================

	if diferencia <= rango_permitido:

		label_resultado.text = (
			"PERFECTO"
		)

		label_resultado.modulate = (
			Color.GREEN
		)

		await get_tree() \
		.create_timer(1.0).timeout

		await cinematica \
		.notificar_ganador()

	# =================================================
	# PERDER
	# =================================================

	else:

		label_resultado.text = (
			"FALLASTE"
		)

		label_resultado.modulate = (
			Color.RED
		)

		await get_tree() \
		.create_timer(1.0).timeout

		await cinematica \
		.notificar_perdida()


# TIMER
# =====================================================

func _on_timer_timeout():

	if juego_terminado:
		return

	tiempo_restante -= 1

	label_tiempo.text = (
		"TIEMPO: "
		+ str(tiempo_restante)
	)

	# tensión final
	if tiempo_restante <= 5:

		label_tiempo.modulate = (
			Color.RED
		)

		velocidad_rotacion += 14

	# perder tiempo
	if tiempo_restante <= 0:

		juego_terminado = true
		puede_jugar = false

		label_resultado.text = (
			"SIN TIEMPO"
		)

		label_resultado.modulate = (
			Color.RED
		)

		await cinematica \
		.notificar_perdida(
			"tiempo"
		)
