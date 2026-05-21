extends CinematicaBase
class_name CinematicaReloj

# =====================================================
# VARIABLES
# =====================================================

var hora_objetivo: int = 3
var solucion_texto: String = ""

# =====================================================
# SET SOLUCION
# =====================================================

func set_solucion(hora: int) -> void:

	hora_objetivo = hora

	solucion_texto = get_solucion_texto()

# =====================================================
# TEXTO DIALOGUE
# =====================================================

func get_solucion_texto() -> String:

	return (
		"Debes detener la aguja "
		+ "exactamente en las %02d:00"
	) % hora_objetivo

# =====================================================
# PERDER
# =====================================================

func notificar_perdida(
	tipo := "error"
) -> void:

	var dialogo = (
		dialogue_tiempo
		if tipo == "tiempo"
		else dialogue_perder
	)

	await reproducir_dialogo(dialogo)

	# reiniciar puzzle
	var juego = get_parent()

	if juego.has_method("reiniciar"):
		juego.reiniciar()

	cinematica_terminada.emit()

# =====================================================
# GANAR
# =====================================================

func notificar_ganador() -> void:

	await reproducir_dialogo(
		dialogue_ganar
	)

	marcar_como_vista()

	cambiar_escena()

	cinematica_terminada.emit()

# =====================================================
# DEBUG
# =====================================================

func notificar_progreso(
	precision: float
) -> void:

	print(
		"🕰️ Precisión:",
		precision
	)
