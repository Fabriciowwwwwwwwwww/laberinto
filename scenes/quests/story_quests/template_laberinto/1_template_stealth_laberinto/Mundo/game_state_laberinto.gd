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
func reset():
	player_position = Vector2.ZERO
	player_health = 100.0
	player_inventory.clear()
	llaves = 0
	abiertos.clear()
	objetos_destruidos.clear()
	puertas_ganzua_forzadas.clear()
