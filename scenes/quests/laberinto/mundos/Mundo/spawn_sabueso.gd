# =========================================================
# SPAWNER SABUESOS
# =========================================================
extends Node2D

signal todos_muertos

@export var escena_sabueso: PackedScene
@export var tilemap: TileMapLayer

@export var max_perros := 2

@export var distancia_minima := 250.0
@export var distancia_maxima := 900.0

@export var tiempo_reaparicion := 10.0

var player

# =========================================================
# DATOS PERSISTENTES
# =========================================================

var datos_sabuesos := {}
var oleada_activa := false
# =========================================================
# READY
# =========================================================

func _ready():

	randomize()

	player = get_tree().get_first_node_in_group(
		"player"
	)

	if not player:
		return



# =========================================================
# INICIAR OLEADA
# =========================================================

func iniciar_oleada():

	# ya hay enemigos activos
	if oleada_activa:
		return

	oleada_activa = true

	datos_sabuesos.clear()

	for i in range(max_perros):

		var esquina = obtener_esquina()

		datos_sabuesos[i] = {
			"vida": 100,
			"esquina": esquina,
			"enemigo": null
		}

		crear_sabueso(i)

# =========================================================
# CREAR SABUESO
# =========================================================

func crear_sabueso(id_sabueso: int):

	if not datos_sabuesos.has(id_sabueso):
		return

	var data = datos_sabuesos[id_sabueso]

	var enemigo = escena_sabueso.instantiate()

	enemigo.id_sabueso = id_sabueso
	enemigo.spawner_ref = self

	enemigo.global_position = data["esquina"]

	enemigo.vida = data["vida"]
	enemigo.vida_max = 100

	enemigo.punto_escape = data["esquina"]

	data["enemigo"] = enemigo

	get_tree().current_scene.call_deferred(
		"add_child",
		enemigo
	)

# =========================================================
# CUANDO SE ESCONDE
# =========================================================

func sabueso_escondido(
	id_sabueso: int,
	vida_actual: int
):

	if not datos_sabuesos.has(id_sabueso):
		return

	var data = datos_sabuesos[id_sabueso]

	# guardar vida
	data["vida"] = vida_actual

	# =====================================================
	# SI JUGADOR ESTA MUY LEJOS
	# CAMBIAR ESQUINA
	# =====================================================

	if player.global_position.distance_to(
		data["esquina"]
	) > 400:

		data["esquina"] = obtener_esquina()

	# =====================================================
	# SI MURIO
	# =====================================================

	if vida_actual <= 0:

		data["enemigo"] = null

		var todos_muertos_local := true

		for key in datos_sabuesos:

			if datos_sabuesos[key]["vida"] > 0:
				todos_muertos_local = false
				break

		if todos_muertos_local:

			oleada_activa = false

			todos_muertos.emit()

		return

	# =====================================================
	# REAPARECER
	# =====================================================

	await get_tree().create_timer(
		tiempo_reaparicion
	).timeout

	crear_sabueso(id_sabueso)

# =========================================================
# OBTENER ESQUINA ESCAPE
# =========================================================

func obtener_esquina_escape(
	id_sabueso: int
) -> Vector2:

	if not datos_sabuesos.has(id_sabueso):
		return Vector2.ZERO

	return datos_sabuesos[id_sabueso]["esquina"]

# =========================================================
# OBTENER ESQUINA REAL
# =========================================================

func obtener_esquina() -> Vector2:

	if not player:
		return Vector2.ZERO

	var player_cell = tilemap.local_to_map(
		tilemap.to_local(player.global_position)
	)

	var esquinas_validas: Array[Vector2] = []

	for x in range(-40, 40):

		for y in range(-40, 40):

			var cell = player_cell + Vector2i(x, y)

			if not es_esquina(cell):
				continue

			var world_pos = tilemap.to_global(
				tilemap.map_to_local(cell)
			)

			var dist = world_pos.distance_to(
				player.global_position
			)

			if dist < distancia_minima:
				continue

			if dist > distancia_maxima:
				continue

			var repetida := false

			for key in datos_sabuesos:

				var esquina_existente = datos_sabuesos[key]["esquina"]

				if esquina_existente.distance_to(
					world_pos
				) < 180:

					repetida = true
					break

			if repetida:
				continue

			esquinas_validas.append(world_pos)

	if esquinas_validas.is_empty():
		return player.global_position + Vector2(300, 0)

	esquinas_validas.shuffle()

	return esquinas_validas[0]

# =========================================================
# ES ESQUINA
# =========================================================

func es_esquina(cell: Vector2i) -> bool:

	if hay_pared(cell):
		return false

	var izquierda = hay_pared(
		cell + Vector2i.LEFT
	)

	var derecha = hay_pared(
		cell + Vector2i.RIGHT
	)

	var arriba = hay_pared(
		cell + Vector2i.UP
	)

	var abajo = hay_pared(
		cell + Vector2i.DOWN
	)

	if izquierda and arriba:
		return true

	if derecha and arriba:
		return true

	if izquierda and abajo:
		return true

	if derecha and abajo:
		return true

	return false

# =========================================================
# HAY PARED
# =========================================================

func hay_pared(cell: Vector2i) -> bool:

	return tilemap.get_cell_source_id(cell) != -1
