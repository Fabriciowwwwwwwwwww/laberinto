extends CharacterBody2D

@export var velocidad := 80
@export var radio_arbol := 140

# 🔥 ATAQUE
@export var dano := 10
@export var tiempo_entre_ataques := 1.0

var puede_atacar := true
var jugador_en_rango := false
var jugador = null

# 🔥 AREA DE ATAQUE
@onready var area_ataque: Area2D = $AreaAtaque

# 🔥 CANVAS
@onready var canvas_daño = get_tree().current_scene.get_node("CanvasLayer")
@onready var anim_daño = canvas_daño.get_node("AnimatedSprite2D")

# 🔥 estados
enum Estado { PATRULLA, PERSEGUIR, VOLVER }
var estado = Estado.PATRULLA

# 🔥 CONTROL PERSECUCIÓN
var tiempo_perseguir := 0.0
var tiempo_max_perseguir := 3.0

# 🔥 POSICIÓN ORIGINAL
var posicion_inicio: Vector2

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
	add_to_group("enemy")
	jugador = get_tree().get_first_node_in_group("player")
	randomize()

	posicion_inicio = global_position

	area_ataque.body_entered.connect(_on_body_entered)
	area_ataque.body_exited.connect(_on_body_exited)


# ---------------------------------------------------
func _physics_process(delta):

	if not jugador:
		return

	match estado:
		Estado.PATRULLA:
			patrullar(delta)

		Estado.PERSEGUIR:
			seguir_jugador(delta)

		Estado.VOLVER:
			volver_a_posicion()

	# 🔥 ARBOLES (LO QUE TE FALTABA)
	afectar_arboles()

	move_and_slide()

	intentar_atacar()


# ---------------------------------------------------
# 🎯 DETECCIÓN
func _on_body_entered(body):
	if body.is_in_group("player"):
		jugador_en_rango = true
		jugador = body

		# 🔥 guardar punto antes de perseguir
		posicion_inicio = global_position

		estado = Estado.PERSEGUIR
		tiempo_perseguir = tiempo_max_perseguir


func _on_body_exited(body):
	if body.is_in_group("player"):
		jugador_en_rango = false


# ---------------------------------------------------
# 💥 ATAQUE
func intentar_atacar():

	if not puede_atacar:
		return

	if jugador_en_rango and jugador:

		puede_atacar = false

		if jugador.has_method("recibir_daño"):
			jugador.recibir_daño(dano)

		mostrar_efecto_daño()

		await get_tree().create_timer(tiempo_entre_ataques).timeout
		puede_atacar = true


# ---------------------------------------------------
# 🔥 EFECTO DAÑO
func mostrar_efecto_daño():

	if canvas_daño:
		canvas_daño.visible = true

		if anim_daño:
			anim_daño.play("daño")

		await get_tree().create_timer(0.4).timeout
		canvas_daño.visible = false


# ---------------------------------------------------
# 👾 PERSEGUIR (CON TIEMPO LIMITADO)
func seguir_jugador(delta):

	tiempo_perseguir -= delta

	var dir = (jugador.global_position - global_position).normalized()

	dir += Vector2(
		randf_range(-0.2, 0.2),
		randf_range(-0.2, 0.2)
	)

	velocity = dir.normalized() * velocidad * 1.4

	# 🔥 TERMINA PERSECUCIÓN
	if tiempo_perseguir <= 0:
		estado = Estado.VOLVER


# ---------------------------------------------------
# 🔙 VOLVER AL PUNTO
func volver_a_posicion():

	var dir = (posicion_inicio - global_position)

	if dir.length() < 10:
		estado = Estado.PATRULLA
		recorrido.clear()
		return

	velocity = dir.normalized() * velocidad


# ---------------------------------------------------
# 🌲 ARBOLES (RECUPERADO)
func afectar_arboles():

	var arboles = get_tree().get_nodes_in_group("arbol")

	for a in arboles:
		var dist = global_position.distance_to(a.global_position)

		if dist < radio_arbol and randf() < 0.2:
			if a.has_method("sacudir"):
				a.sacudir()


# ---------------------------------------------------
# 🧠 PATRULLA
func generar_recorrido():

	recorrido.clear()

	var pasos = randi_range(3, 6)
	var ultima_dir = Vector2.ZERO

	for i in range(pasos):

		var opciones = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
		opciones.erase(ultima_dir)

		var dir = opciones[randi() % opciones.size()]

		recorrido.append(dir)
		ultima_dir = dir

	recorrido_reversa = recorrido.duplicate()
	recorrido_reversa.reverse()

	indice_recorrido = 0
	yendo_reversa = false


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
					tiempo_perseguir = tiempo_max_perseguir
					repeticiones = 0
					recorrido.clear()
					return

		tiempo_mov = randf_range(1.5, 3.0)

	var lista = recorrido_reversa if yendo_reversa else recorrido
	velocity = lista[indice_recorrido] * velocidad
