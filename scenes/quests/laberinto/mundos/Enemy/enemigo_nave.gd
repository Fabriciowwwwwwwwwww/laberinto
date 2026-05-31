extends CharacterBody2D

signal damage(value: float)
signal died

# =====================================================
# ESTADOS
# =====================================================

enum State {
	CHASE,
	WARNING,
	ABDUCTING,
	COOLDOWN
}

var current_state = State.CHASE

# =====================================================
# MOVIMIENTO
# =====================================================

@export var velocidad := 120.0
@export var aceleracion := 6.0

# =====================================================
# VIDA
# =====================================================

@export var vida_maxima := 100.0
var vida_actual := 0.0

# =====================================================
# TIEMPO VIDA
# =====================================================

@export var tiempo_vida := 180.0

# =====================================================
# ABDUCCION
# =====================================================

@export var presses_necesarios := 4

# altura sobre jugador
@export var altura_abduccion := 90.0

# tiempo de preparacion
@export var tiempo_preparacion := 3.0

# tiempo maximo abduciendo
@export var tiempo_rayo := 2.0

# cooldown antes de volver
@export var cooldown_abduccion := 5.0

# =====================================================
# VARIABLES
# =====================================================

var jugador_abducido : Node2D = null
var presses_actuales := 0
var puede_abducir := true
var atrapando := false

# =====================================================
# REFERENCIAS
# =====================================================

var objetivo : Node2D

@onready var progreso: ProgressBar = $barra_progreso
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@onready var area_abduccion: Area2D = $AreaAbduccion
@onready var laser_anim: AnimatedSprite2D = $AreaAbduccion/LaserSprite/AnimatedSprite2D

@onready var golpe_audio: AudioStreamPlayer2D = $golpe
@onready var idle_audio: AudioStreamPlayer2D = $idle

# =====================================================
# READY
# =====================================================

func _ready():
	add_to_group("boss_minion")
	vida_actual = vida_maxima

	progreso.max_value = presses_necesarios
	progreso.value = 0
	progreso.visible = false

	buscar_objetivo()

	anim.play("idle")

	# laser apagado
	laser_anim.visible = false

	# area desactivada
	area_abduccion.monitoring = false

	# sonido idle
	idle_audio.play()

	# vida limitada
	await get_tree().create_timer(tiempo_vida).timeout

	if is_inside_tree():
		queue_free()

# =====================================================
# PHYSICS
# =====================================================

func _physics_process(delta):

	if objetivo == null:
		buscar_objetivo()
		return

	match current_state:

		State.CHASE:
			chase_state(delta)

		State.WARNING:
			warning_state(delta)

		State.ABDUCTING:
			abducting_state(delta)

		State.COOLDOWN:
			cooldown_state(delta)

# =====================================================
# CHASE
# =====================================================

func chase_state(delta):

	if not puede_abducir:
		return

	if objetivo == null:
		return

	# =================================================
	# IR ENCIMA DEL JUGADOR
	# =================================================

	var target_pos = objetivo.global_position + Vector2(0, -altura_abduccion)

	var dir = (target_pos - global_position).normalized()

	var target_velocity = dir * velocidad

	velocity = velocity.lerp(target_velocity, aceleracion * delta)

	move_and_slide()

	actualizar_flip()

	if anim.animation != "fly":
		anim.play("fly")

	# =================================================
	# YA ESTA ENCIMA
	# =================================================

	if global_position.distance_to(target_pos) <= 10:

		iniciar_preparacion()

# =====================================================
# WARNING
# =====================================================

func warning_state(delta):

	velocity = Vector2.ZERO

	move_and_slide()

	if anim.animation != "abduct":
		anim.play("abduct")

# =====================================================
# ABDUCTING
# =====================================================

func abducting_state(delta):

	velocity = Vector2.ZERO

	move_and_slide()

	if anim.animation != "abduct":
		anim.play("abduct")

	controlar_escape()

# =====================================================
# COOLDOWN
# =====================================================

func cooldown_state(delta):

	velocity = Vector2.ZERO

	move_and_slide()

	if anim.animation != "idle":
		anim.play("idle")

# =====================================================
# OBJETIVO
# =====================================================

func buscar_objetivo():

	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		objetivo = players[0]

# =====================================================
# FLIP
# =====================================================

func actualizar_flip():

	if velocity.x != 0:
		anim.flip_h = velocity.x < 0

# =====================================================
# PREPARAR ABDUCCION
# =====================================================

func iniciar_preparacion():

	if not puede_abducir:
		return

	puede_abducir = false

	current_state = State.WARNING

	velocity = Vector2.ZERO

	anim.play("abduct")

	# =================================================
	# ANIMACION INICIO LASER
	# =================================================

	laser_anim.visible = true
	laser_anim.play("inicio")

	# esperar animacion + preparacion
	await get_tree().create_timer(tiempo_preparacion).timeout

	if not is_inside_tree():
		return

	iniciar_rayo()

# =====================================================
# INICIAR RAYO
# =====================================================

func iniciar_rayo():

	current_state = State.ABDUCTING

	atrapando = true

	# =================================================
	# ACTIVAR AREA
	# =================================================

	area_abduccion.monitoring = true

	# =================================================
	# ANIMACION LASER ACTIVO
	# =================================================

	laser_anim.play("abduccion")

	# =================================================
	# TIEMPO LIMITE
	# =================================================

	await get_tree().create_timer(tiempo_rayo).timeout

	if not is_inside_tree():
		return

	finalizar_abduccion()

# =====================================================
# DETECTAR PLAYER
# =====================================================

func _on_area_abduccion_body_entered(body):

	if not atrapando:
		return

	if not body.is_in_group("player"):
		return

	if jugador_abducido != null:
		return

	jugador_abducido = body

	body.inmovilizado = true

	progreso.visible = true
	progreso.value = 0

	presses_actuales = 0

# =====================================================
# ESCAPE
# =====================================================

func controlar_escape():

	if jugador_abducido == null:
		return

	if Input.is_action_just_pressed("ui_accept"):

		presses_actuales += 1

		progreso.value = presses_actuales

		print("ESCAPE:", presses_actuales)

		if presses_actuales >= presses_necesarios:

			jugador_abducido.inmovilizado = false

			jugador_abducido = null

			finalizar_abduccion()

# =====================================================
# FINALIZAR
# =====================================================

func finalizar_abduccion():

	atrapando = false

	current_state = State.COOLDOWN

	# =================================================
	# DESACTIVAR AREA
	# =================================================

	area_abduccion.monitoring = false

	# =================================================
	# ANIMACION FINAL LASER
	# =================================================

	laser_anim.play("final")

	await laser_anim.animation_finished

	laser_anim.visible = false

	# =================================================
	# RESET UI
	# =================================================

	progreso.visible = false
	progreso.value = 0

	presses_actuales = 0

	# =================================================
	# LIBERAR PLAYER
	# =================================================

	if jugador_abducido != null:
		jugador_abducido.inmovilizado = false

	jugador_abducido = null

	reiniciar_cooldown()

# =====================================================
# COOLDOWN
# =====================================================

func reiniciar_cooldown():

	await get_tree().create_timer(cooldown_abduccion).timeout

	if not is_inside_tree():
		return

	puede_abducir = true

	current_state = State.CHASE

# =====================================================
# DAÑO
# =====================================================

func recibir_daño(cantidad):

	if vida_actual <= 0:
		return

	vida_actual -= cantidad

	damage.emit(cantidad)

	golpe_audio.play()

	anim.modulate = Color.RED

	await get_tree().create_timer(0.1).timeout

	anim.modulate = Color.WHITE

	if vida_actual <= 0:
		morir()

# =====================================================
# MUERTE
# =====================================================

func morir():

	died.emit()

	if jugador_abducido != null:
		jugador_abducido.inmovilizado = false

	queue_free()
