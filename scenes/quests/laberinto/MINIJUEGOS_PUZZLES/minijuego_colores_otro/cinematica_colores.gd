extends CinematicaBase
class_name CinematicaColores_otro

# =========================
# REFERENCIAS
# =========================

@onready var label_countdown: Label = %LabelCuentaAtras

# =========================
# EXPORTS
# =========================

@export var tiempo_mostrar: float = 6.0

# =========================
# VARIABLES
# =========================

var puzzle_ref: Node = null
var solucion := {}
var escena_solucion: Node = null

# =========================
# READY
# =========================

func _ready():
	if label_countdown:
		label_countdown.visible = false

# =========================
# SETTERS
# =========================

func set_puzzle(p):
	puzzle_ref = p

func set_solucion(sol: Dictionary):
	solucion = sol.duplicate()

func set_escena_solucion(e):
	escena_solucion = e

# =========================
# INTRO
# =========================

func ejecutar_secuencia_intro():

	print("🎬 INTRO")

	# diálogo intro
	await reproducir_dialogo(dialogue_intro)

	# countdown
	await ejecutar_cuenta_atras()

	cinematica_terminada.emit()

# =========================
# DERROTA
# =========================

func ejecutar_derrota():

	print("💀 DERROTA CINEMATICA")

	# diálogo derrota
	await reproducir_dialogo(dialogue_perder)

	# countdown
	await ejecutar_cuenta_atras()

# =========================
# VICTORIA
# =========================

func ejecutar_victoria():

	print("🏆 VICTORIA CINEMATICA")

	# diálogo victoria
	await reproducir_dialogo(dialogue_ganar)

	# cambiar escena
	cambiar_escena()

# =========================
# CUENTA ATRÁS
# =========================

func ejecutar_cuenta_atras():

	if not label_countdown:
		print("❌ LabelCuentaAtras no encontrado")
		return

	# ocultar cronómetro del gameplay
	if puzzle_ref:
		puzzle_ref.ocultar_cronometro()

	label_countdown.visible = true
	label_countdown.modulate = Color.WHITE

	# countdown
	for i in range(5, 0, -1):

		label_countdown.text = str(i)

		print("⏳", i)

		await get_tree().create_timer(1.0).timeout

	label_countdown.visible = false

	# volver cronómetro gameplay
	if puzzle_ref:
		puzzle_ref.mostrar_cronometro()
