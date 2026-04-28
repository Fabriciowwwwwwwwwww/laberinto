extends CinematicaBase
class_name CinematicaCartas

# 🎬 DIÁLOGOS ESPECÍFICOS (Los básicos ya vienen del padre)
@export var progreso_dialogue: DialogueResource 
@export var previo_final_dialogue: DialogueResource
@export var final_dialogue: DialogueResource

# 🧠 DATOS
var solucion_actual: Array = []
var tipo_operacion: String = ""
var objetivo: int = 0

# -------------------------
# SETUP (Lógica específica)
# -------------------------
func set_solucion(sol: Array, tipo: String, valor_objetivo: int) -> void:
	solucion_actual = sol.duplicate()
	tipo_operacion = tipo
	objetivo = valor_objetivo
	print("📥 Cartas recibe: ", solucion_actual, " Tipo: ", tipo_operacion, " Obj: ", objetivo)

# -------------------------
# EVENTOS DE ESTADO (Usando al Padre)
# -------------------------

func notificar_progreso(actual: int, total: int) -> void:
	print("🃏 Progreso Cartas:", actual, "/", total)
	await reproducir_dialogo(progreso_dialogue)
	cinematica_terminada.emit()

func notificar_perdida(tipo := "error") -> void:
	var dialogo = dialogue_tiempo if tipo == "tiempo" else dialogue_perder
	await reproducir_dialogo(dialogo)
	cinematica_terminada.emit()

# -------------------------
# SECUENCIA FINAL
# -------------------------

func notificar_previo_final() -> void:
	await reproducir_dialogo(previo_final_dialogue)
	cinematica_terminada.emit()

func notificar_final_ganado() -> void:
	# 1. Diálogo final
	await reproducir_dialogo(final_dialogue)
	
	# 2. Persistencia (Heredado)
	marcar_como_vista()
	
	# 3. Cambio de escena (Heredado)
	cambiar_escena()
	
	cinematica_terminada.emit()
