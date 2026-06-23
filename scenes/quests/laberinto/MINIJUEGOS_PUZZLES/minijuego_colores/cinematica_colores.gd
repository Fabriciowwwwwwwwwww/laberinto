extends CinematicaBase
class_name CinematicaColores

# =========================
# REFERENCIAS
# =========================


# =========================
# VARIABLES
# =========================

var puzzle_ref: Node = null


# =========================
# READY
# =========================



# =========================
# SETTERS
# =========================

func set_puzzle(p):
	puzzle_ref = p



# =========================
# INTRO
# =========================
func ejecutar_secuencia_intro():

	print("🎬 INTRO EJECUTADA")

	await reproducir_dialogo(dialogue_intro)

	print("🎬 EMITIENDO SEÑAL")

	cinematica_terminada.emit()

# =========================
# DERROTA
# =========================

func ejecutar_derrota():

	print("💀 DERROTA CINEMATICA")

	# diálogo derrota
	await reproducir_dialogo(dialogue_perder)


# =========================
# VICTORIA
# =========================

func ejecutar_victoria():

	await reproducir_dialogo(dialogue_ganar)

	# cambiar escena
	cambiar_escena()

# =========================
# CUENTA ATRÁS
# =========================
