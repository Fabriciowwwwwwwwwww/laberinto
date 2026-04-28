extends CinematicaBase
class_name CinematicaEngranaje

var solucion_actual: Array = []
# Creamos la variable que el archivo .dialogue está buscando
var solucion_texto: String = "" 

func set_solucion(sol: Array) -> void:
	solucion_actual = sol.duplicate()
	# Actualizamos la variable cada vez que cambia la solución
	solucion_texto = get_solucion_texto() 
	print("📥 SOLUCIÓN ACTUALIZADA en Engranajes")

func get_solucion_texto() -> String:
	var texto := ""
	for i in range(solucion_actual.size()):
		texto += "Engranaje %d -> %s\n" % [
			i + 1,
			"Derecha" if solucion_actual[i] == 0 else "Izquierda"
		]
	return texto
# -------------------------
# EVENTOS DE JUEGO (Usando al Padre)
# -------------------------

func notificar_perdida(tipo := "error") -> void:
	# Elegimos el recurso según el tipo de fallo
	var dialogo = dialogue_tiempo if tipo == "tiempo" else dialogue_perder
	
	# El padre apaga música, muestra el globo y vuelve a encender la música
	await reproducir_dialogo(dialogo)
	
	cinematica_terminada.emit()

func notificar_ganador() -> void:
	# 1. Diálogo de victoria
	await reproducir_dialogo(dialogue_ganar)
	
	# 2. Persistencia y cambio de escena (Funciones del padre)
	marcar_como_vista()
	cambiar_escena()
	
	cinematica_terminada.emit()

func notificar_progreso(actual: int, total: int) -> void:
	print("⚙️ Progreso Engranajes:", actual, "/", total)
	# Si quieres un diálogo cada vez que aciertan uno, puedes llamarlo aquí:
	# await reproducir_dialogo(recurso_progreso)
