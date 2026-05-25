extends Node2D

@export var escena_sabueso: PackedScene
@export var tilemap: TileMapLayer

@export var max_perros := 2

@export var distancia_minima := 180.0
@export var distancia_maxima := 500.0

@export var radio_busqueda := 12

var player

# ==================================================
# READY
# ==================================================

func _ready():

	print("Spawner listo")

	player = get_tree().get_first_node_in_group(
		"player"
	)

	if not player:
		print("NO PLAYER")
		return

	for i in range(max_perros):

		crear_perro()

# ==================================================
# CREAR PERRO
# ==================================================
func crear_perro():

	var esquina = obtener_esquina()

	if esquina == Vector2.ZERO:

		print("NO SE ENCONTRO ESQUINA")
		return

	print("SPAW EN ", esquina)

	# ==================================================
	# DEBUG VISUAL
	# ==================================================

	var debug = ColorRect.new()

	debug.color = Color.RED

	debug.size = Vector2(32, 32)

	debug.position = esquina - Vector2(16,16)

	debug.z_index = 9999

	get_tree().current_scene.add_child(debug)

	# destruir luego
	var tween = create_tween()

	tween.tween_interval(3.0)

	tween.tween_callback(debug.queue_free)

	# ==================================================
	# CREAR PERRO
	# ==================================================

	var perro = escena_sabueso.instantiate()

	get_tree().current_scene.add_child(perro)

	perro.global_position = esquina

	print("sabueso creado")
# ==================================================
# OBTENER ESQUINA
# ==================================================

func obtener_esquina() -> Vector2:

	if not player:
		return Vector2.ZERO

	for i in range(80):

		var random_offset = Vector2(
			randf_range(-500, 500),
			randf_range(-500, 500)
		)

		var pos = player.global_position + random_offset

		var dist = pos.distance_to(
			player.global_position
		)

		# demasiado cerca
		if dist < distancia_minima:
			continue

		# raycast para buscar pared cercana
		if cerca_de_pared(pos):

			return pos

	return Vector2.ZERO
func cerca_de_pared(pos: Vector2) -> bool:

	var space = get_world_2d().direct_space_state

	var dirs = [
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.DOWN
	]

	for dir in dirs:

		var query = PhysicsRayQueryParameters2D.create(
			pos,
			pos + dir * 40
		)

		var result = space.intersect_ray(query)

		if not result.is_empty():

			return true

	return false
func es_esquina(cell: Vector2i) -> bool:

	# centro libre
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

# ==================================================
# HAY PARED
# ==================================================

func hay_pared(cell: Vector2i) -> bool:

	return tilemap.get_cell_source_id(cell) != -1
