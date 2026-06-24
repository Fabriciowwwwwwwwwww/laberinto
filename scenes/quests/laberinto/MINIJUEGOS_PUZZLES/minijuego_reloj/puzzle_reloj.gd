extends Node2D

# =====================================================
# RELOJES
# =====================================================

@onready var aguja_1 = $AgujaPivot
@onready var aguja_2 = $AgujaPivot2
var controles_habilitados := false
@onready var zona_1 = $ClockBase1/ZonaObjetivo
@onready var zona_2 = $ClockBase2/ZonaObjetivo2
var boton_seleccionado := 0 # 0 = izquierda, 1 = derecha
# =====================================================
# UI
# =====================================================

@onready var label_hora_1 = $CanvasLayer/PanelIzquierdo/LabelHoraObjetivo_izquierda
@onready var label_hora_2 = $CanvasLayer/PanelIzquierdo/LabelHoraObjetivo_derecha

@onready var label_tiempo = $CanvasLayer/PanelIzquierdo/LabelTiempo

@onready var barra_1 = $CanvasLayer/PanelDerecho/BarraPrecision
@onready var barra_2 = $CanvasLayer/PanelDerecho/BarraPrecision2

@onready var resultado_1 = $CanvasLayer/PanelDerecho/LabelResultado
@onready var resultado_2 = $CanvasLayer/PanelDerecho/LabelResultado2

@onready var boton_1 = $CanvasLayer/BotonDetener_izquierda
@onready var boton_2 = $CanvasLayer/BotonDetener_derecha

@onready var timer = $Timer
@onready var cinematica = $cinematica

# =====================================================
# CONFIG
# =====================================================

@export var velocidad_min := 260.0
@export var velocidad_max := 420.0

@export var rango_permitido := 10.0
@export var radio_zona := 230.0

# =====================================================
# VARIABLES RELOJ 1
# =====================================================

var rotacion_1 := 0.0
var velocidad_1 := 300.0
var hora_1 := 3
var angulo_1 := 0.0
var detenido_1 := false

# =====================================================
# VARIABLES RELOJ 2
# =====================================================

var rotacion_2 := 0.0
var velocidad_2 := 300.0
var hora_2 := 6
var angulo_2 := 0.0
var detenido_2 := false

# =====================================================
# GENERAL
# =====================================================

var juego_terminado := false
var tiempo_restante := 15

# =====================================================
# READY
# =====================================================

func _ready():
	boton_1.focus_mode = Control.FOCUS_ALL
	boton_2.focus_mode = Control.FOCUS_ALL


	randomize()

	boton_1.pressed.connect(detener_reloj_1)
	boton_2.pressed.connect(detener_reloj_2)

	iniciar_minijuego()


# =====================================================
# INICIAR
# =====================================================
func actualizar_seleccion():

	if boton_seleccionado == -1:
		get_viewport().gui_release_focus()
		return

	if boton_seleccionado == 0:
		boton_1.grab_focus()

	elif boton_seleccionado == 1:
		boton_2.grab_focus()
func iniciar_minijuego():
	controles_habilitados = false
	boton_seleccionado = -1

	actualizar_seleccion()

	await get_tree().create_timer(1.0).timeout

	controles_habilitados = true
	juego_terminado = false

	detenido_1 = false
	detenido_2 = false

	# velocidades
	velocidad_1 = randf_range(
		velocidad_min,
		velocidad_max
	)

	velocidad_2 = randf_range(
		velocidad_min,
		velocidad_max
	)

	# rotaciones iniciales
	rotacion_1 = randf_range(0, 360)
	rotacion_2 = randf_range(0, 360)

	generar_horas()

	tiempo_restante = 15

	timer.start()

# =====================================================
# GENERAR HORAS
# =====================================================

func generar_horas():

	# RELOJ 1
	hora_1 = randi_range(1, 12)

	label_hora_1.text = (
		"%02d:00"
		% hora_1
	)

	angulo_1 = wrapf(
		((hora_1 % 12) * 30) - 90,
		0,
		360
	)

	crear_zona(
		zona_1,
		angulo_1
	)

	# RELOJ 2
	hora_2 = randi_range(1, 12)

	label_hora_2.text = (
		"%02d:00"
		% hora_2
	)

	angulo_2 = wrapf(
		((hora_2 % 12) * 30) - 90,
		0,
		360
	)

	crear_zona(
		zona_2,
		angulo_2
	)

# =====================================================
# CREAR ZONA
# =====================================================

func crear_zona(zona, angulo_objetivo):

	var inicio = deg_to_rad(
		angulo_objetivo - rango_permitido
	)

	var fin = deg_to_rad(
		angulo_objetivo + rango_permitido
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

	zona.polygon = puntos

	zona.color = Color(
		0.8,
		0,
		0,
		0.85
	)

# =====================================================
# PROCESS
# =====================================================

func _process(delta):

	if juego_terminado:
		return
	if !controles_habilitados:
		return
	# RELOJ 1
	if !detenido_1:

		rotacion_1 += velocidad_1 * delta
		rotacion_1 = wrapf(rotacion_1, 0, 360)

		aguja_1.rotation_degrees = rotacion_1

	# RELOJ 2
	if !detenido_2:

		rotacion_2 += velocidad_2 * delta
		rotacion_2 = wrapf(rotacion_2, 0, 360)

		aguja_2.rotation_degrees = rotacion_2
	# Cambiar selección con joystick o cruceta

	if Input.is_action_just_pressed("ui_left"):
		boton_seleccionado = 0
		actualizar_seleccion()

	if Input.is_action_just_pressed("ui_right"):
		boton_seleccionado = 1
		actualizar_seleccion()

	if Input.is_action_just_pressed("Interact"):

		if boton_seleccionado == -1:
			return

		if boton_seleccionado == 0:
			boton_1.emit_signal("pressed")

		elif boton_seleccionado == 1:
			boton_2.emit_signal("pressed")

# =====================================================
# DETENER RELOJ 1
# =====================================================

func detener_reloj_1():

	if detenido_1:
		return

	detenido_1 = true

	var diferencia = abs(
		wrapf(
			rotacion_1 - angulo_1,
			-180,
			180
		)
	)

	var precision = clamp(
		100.0 - (
			(diferencia / rango_permitido)
			* 100.0
		),
		0,
		100
	)

	barra_1.value = precision

	if diferencia <= rango_permitido:

		resultado_1.text = "OK"
		resultado_1.modulate = Color.GREEN

	else:

		resultado_1.text = "X"
		resultado_1.modulate = Color.RED

	verificar_final()

# =====================================================
# DETENER RELOJ 2
# =====================================================

func detener_reloj_2():

	if detenido_2:
		return

	detenido_2 = true

	var diferencia = abs(
		wrapf(
			rotacion_2 - angulo_2,
			-180,
			180
		)
	)

	var precision = clamp(
		100.0 - (
			(diferencia / rango_permitido)
			* 100.0
		),
		0,
		100
	)

	barra_2.value = precision

	if diferencia <= rango_permitido:

		resultado_2.text = "OK"
		resultado_2.modulate = Color.GREEN

	else:

		resultado_2.text = "X"
		resultado_2.modulate = Color.RED

	verificar_final()

# =====================================================
# VERIFICAR FINAL
# =====================================================

func verificar_final():

	# esperar ambos
	if !detenido_1 or !detenido_2:
		return

	juego_terminado = true

	var gana_1 = resultado_1.text == "OK"
	var gana_2 = resultado_2.text == "OK"

	await get_tree().create_timer(1.0).timeout

	if gana_1 and gana_2:

		await cinematica.notificar_ganador()

	else:

		await cinematica.notificar_perdida()

		await get_tree().create_timer(1.0).timeout

		reiniciar_puzzle()
func reiniciar_puzzle():

	juego_terminado = false

	detenido_1 = false
	detenido_2 = false

	# limpiar UI
	resultado_1.text = ""
	resultado_2.text = ""

	barra_1.value = 0
	barra_2.value = 0

	label_tiempo.modulate = Color.WHITE

	# reiniciar velocidades
	velocidad_1 = randf_range(
		velocidad_min,
		velocidad_max
	)

	velocidad_2 = randf_range(
		velocidad_min,
		velocidad_max
	)

	# nuevas posiciones
	rotacion_1 = randf_range(0, 360)
	rotacion_2 = randf_range(0, 360)

	# nuevas horas
	generar_horas()

	tiempo_restante = 15

	label_tiempo.text = (
		"TIEMPO: "
		+ str(tiempo_restante)
	)

	timer.start()
# =====================================================
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

	if tiempo_restante <= 5:

		label_tiempo.modulate = Color.RED

		velocidad_1 += 14
		velocidad_2 += 14

	if tiempo_restante <= 0:

		juego_terminado = true

		await cinematica.notificar_perdida("tiempo")

		await get_tree().create_timer(1.0).timeout

		reiniciar_puzzle()
