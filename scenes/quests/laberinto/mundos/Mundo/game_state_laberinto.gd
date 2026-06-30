extends Node
# -------------------- ESTADO DEL JUGADOR --------------------
var player_position: Vector2 = Vector2.ZERO
var player_health: float = 100.0                  # salud del jugador
var llaves: int = 0                               # Número de llaves recogidas
var player_inventory: Array = []                  # Items recogidos o usados

# -------------------- OBJETOS Y PUERTAS --------------------
var abiertos: Array = []                           # Cofres, puertas, etc. que han sido abiertos
var objetos_destruidos: Array = []                # IDs de objetos destruidos o usados
var puertas_ganzua_forzadas := {}                # Puertas forzadas con ganzúa
# -------------------- ESTADÍSTICAS --------------------
var enemigos_eliminados: int = 0
var puertas_abiertas: int = 0
var cofres_abiertos: int = 0
var experiencia_obtenida: int = 0
var dano_recibido: int = 0


var tiempo_inicio: int = 0
var tiempo_fin: int = 0
# -------------------- FUNCIONES --------------------

# Guardar estado del jugador
func save_player(jugador: Player_l) -> void:
	player_position = jugador.global_position
	player_health = jugador.vida_actual          # <--- usar player_health
	llaves = jugador.keys_collected
	abiertos = jugador.get_cofres_abiertos()
	print("✅ Estado del jugador guardado")

# Restaurar el estado del jugador
func restore_player(jugador: Player_l) -> void:
	jugador.global_position = player_position
	jugador.vida_actual = player_health          # <--- usar player_health
	jugador.keys_collected = llaves
	jugador.set_cofres_abiertos(abiertos)
	jugador.update_keys_ui()
	if jugador.vida_bar:
		jugador.vida_bar.value = jugador.vida_actual
		jugador.actualizar_color_vida()
	print("✅ Estado del jugador restaurado")

# Guardar que un objeto fue destruido o usado
func mark_objeto_destruido(obj_id: String):
	if obj_id not in objetos_destruidos:
		objetos_destruidos.append(obj_id)

# Verificar si un objeto ya fue destruido
func is_objeto_destruido(obj_id: String) -> bool:
	return obj_id in objetos_destruidos

# Reiniciar todo el juego
func reset()-> void:
	player_position = Vector2.ZERO
	player_health = 100.0
	player_inventory.clear()
	llaves = 0
	abiertos.clear()
	objetos_destruidos.clear()
	puertas_ganzua_forzadas.clear()

	# Estadísticas
	cofres_abiertos = 0
	experiencia_obtenida = 0
	dano_recibido = 0
	enemigos_eliminados = 0
	puertas_abiertas = 0
	experiencia_obtenida = 0
	tiempo_inicio = 0
	tiempo_fin = 0
# -------------------- ESTADÍSTICAS --------------------

func iniciar_partida() -> void:
	enemigos_eliminados = 0
	puertas_abiertas = 0
	experiencia_obtenida = 0

	tiempo_inicio = Time.get_ticks_msec()
	tiempo_fin = 0


func finalizar_partida() -> void:
	tiempo_fin = Time.get_ticks_msec()


func tiempo_partida_segundos() -> int:
	var fin := tiempo_fin

	if fin == 0:
		fin = Time.get_ticks_msec()

	return int((fin - tiempo_inicio) / 1000)


func tiempo_formateado() -> String:
	var total := tiempo_partida_segundos()

	var horas := total / 3600
	var minutos := (total % 3600) / 60
	var segundos := total % 60

	return "%02d:%02d:%02d" % [horas, minutos, segundos]
