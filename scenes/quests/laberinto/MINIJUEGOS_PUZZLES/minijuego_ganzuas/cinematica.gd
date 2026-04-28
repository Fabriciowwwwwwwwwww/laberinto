extends CinematicaBase
class_name CinematicaGanzuas

var perdidas: int = 0
var ha_ganado: bool = false
var esta_reproduciendo: bool = false 

func _ready() -> void:
	super._ready()

# ---------------------------------------------------
# LÓGICA DE FALLO
# ---------------------------------------------------
func notificar_perdida() -> void:
	if esta_reproduciendo:
		return
	
	esta_reproduciendo = true
	perdidas += 1
	
	var dialogo_a_usar: DialogueResource = null

	if perdidas == 1:
		dialogo_a_usar = dialogue_tiempo 
	else:
		dialogo_a_usar = dialogue_perder
	
	if dialogo_a_usar:
		await reproducir_dialogo(dialogo_a_usar)
		# Devolvemos la música siempre, ya que no hay NPC que esperar
		MusicManager.fade_in(1.0)

	esta_reproduciendo = false
	cinematica_terminada.emit()

# -------------------------
# LÓGICA DE VICTORIA
# -------------------------
func notificar_ganador() -> void:
	if esta_reproduciendo:
		return
		
	esta_reproduciendo = true
	ha_ganado = true
	
	await reproducir_dialogo(dialogue_ganar)
	
	marcar_como_vista()
	
	if usar_next_scene:
		cambiar_escena()
	else:
		# Si nos quedamos en la escena, devolvemos la música
		MusicManager.fade_in(1.0)
	
	esta_reproduciendo = false
	cinematica_terminada.emit()
