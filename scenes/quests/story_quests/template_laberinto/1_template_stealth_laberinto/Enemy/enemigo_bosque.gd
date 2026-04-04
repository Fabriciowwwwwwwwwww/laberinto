extends CharacterBody2D

@export var velocidad := 80
@export var radio_arbol := 140

var jugador

# 🔥 estados
enum Estado { PATRULLA, PERSEGUIR, ESCONDERSE, ATACAR }
var estado = Estado.PATRULLA

# 🔥 control estados
var tiempo_perseguir := 0.0
var iniciando_persecucion := true

# 🔥 direcciones
var direcciones_base = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN
]

# 🔥 patrulla
var recorrido: Array = []
var recorrido_reversa: Array = []
var indice_recorrido := 0
var yendo_reversa := false

var tiempo_mov := 0.0
var repeticiones := 0
var max_repeticiones := 3

# ---------------------------------------------------
func _ready():
	add_to_group("enemigo")
	jugador = get_tree().get_first_node_in_group("player")
	randomize()

# ---------------------------------------------------
func _physics_process(delta):

	if not jugador:
		return

	match estado:

		Estado.PATRULLA:
			patrullar(delta)

		Estado.PERSEGUIR:
			seguir_jugador(delta)

		Estado.ESCONDERSE:
			ocultarse()

		Estado.ATACAR:
			teletransportarse()

	afectar_arboles()
	move_and_slide()

# ---------------------------------------------------
# 🧠 GENERAR RECORRIDO
func generar_recorrido():

	recorrido.clear()

	var pasos = randi_range(3, 6)
	var ultima_dir = Vector2.ZERO

	for i in range(pasos):

		var opciones = direcciones_base.duplicate()
		opciones.erase(ultima_dir)

		var dir = opciones[randi() % opciones.size()]

		recorrido.append(dir)
		ultima_dir = dir

	recorrido_reversa = recorrido.duplicate()
	recorrido_reversa.reverse()

	indice_recorrido = 0
	yendo_reversa = false

# ---------------------------------------------------
# 🔁 PATRULLA
func patrullar(delta):

	if recorrido.is_empty():
		generar_recorrido()
		tiempo_mov = 2.0

	tiempo_mov -= delta

	if tiempo_mov <= 0:

		indice_recorrido += 1

		var lista_actual = recorrido_reversa if yendo_reversa else recorrido

		if indice_recorrido >= lista_actual.size():

			indice_recorrido = 0

			if not yendo_reversa:
				yendo_reversa = true
			else:
				yendo_reversa = false
				repeticiones += 1

				if repeticiones >= max_repeticiones:
					estado = Estado.PERSEGUIR
					
					# 🔥 AQUÍ VA
					tiempo_perseguir = randf_range(3.0, 6.0)

					repeticiones = 0
					recorrido.clear()
					return

		tiempo_mov = randf_range(1.5, 3.0)

	var lista = recorrido_reversa if yendo_reversa else recorrido
	var dir = lista[indice_recorrido]

	velocity = dir * velocidad

# ---------------------------------------------------
# 👾 PERSEGUIR (CORREGIDO)
func seguir_jugador(delta):

	tiempo_perseguir -= delta

	var dir = (jugador.global_position - global_position).normalized()

	# 🔥 imperfección (más realista)
	dir += Vector2(
		randf_range(-0.2, 0.2),
		randf_range(-0.2, 0.2)
	)

	velocity = dir.normalized() * velocidad * 1.2

	# 🔥 cuando termina el tiempo → vuelve a patrulla
	if tiempo_perseguir <= 0:
		estado = Estado.PATRULLA
		recorrido.clear()

# ---------------------------------------------------
# 👻 ESCONDERSE (SIN BUG)
func ocultarse():

	velocity = Vector2.ZERO
	visible = false

	await get_tree().create_timer(1.5).timeout

	visible = true
	estado = Estado.PATRULLA

# ---------------------------------------------------
# ⚡ TELETRANSPORTE
func teletransportarse():

	var offset = Vector2(
		randf_range(-200, 200),
		randf_range(-200, 200)
	)

	global_position = jugador.global_position + offset

	estado = Estado.PATRULLA

# ---------------------------------------------------
# 🌲 ÁRBOLES
func afectar_arboles():

	var arboles = get_tree().get_nodes_in_group("arbol")

	for a in arboles:
		var dist = global_position.distance_to(a.global_position)

		if dist < radio_arbol and randf() < 0.2:
			if a.has_method("sacudir"):
				a.sacudir()
