# =========================================================
# SABUESO
# =========================================================
extends EnemyBase

enum Estado {
	EMERGIENDO,
	PERSEGUIR,
	HUYENDO,
	ESCONDIDO
}

var estado = Estado.EMERGIENDO

var emergiendo := false

@export var velocidad_huida := 520.0
var velocidad_random := 1.0
var offset_movimiento := Vector2.ZERO
# huir cuando pierda 25%
@export_range(0.0, 1.0)
var porcentaje_huida := 0.75

# =========================================================
# CONTROL SPAWNER
# =========================================================

var spawner_ref = null
var id_sabueso := -1

var punto_escape := Vector2.ZERO

# =========================================================
# READY
# =========================================================

func _ready():

	add_to_group("enemigos")
	add_to_group("sabuesos")

	super()

	if animated_sprite_2d:
		animated_sprite_2d.visible = false

	if vida_bar:
		vida_bar.visible = false

	if vida_etiqueta:
		vida_etiqueta.visible = false

	puede_moverse = false
	puede_atacar = false

	await get_tree().create_timer(0.2).timeout

# velocidad distinta por sabueso
	velocidad_random = randf_range(0.85, 1.15)

	# offset para que no persigan igual
	offset_movimiento = Vector2(
		randf_range(-120, 120),
		randf_range(-120, 120)
	)

	# avoidance
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 28.0
	navigation_agent.neighbor_distance = 140.0
	navigation_agent.max_neighbors = 10

	# alterar velocidades heredadas
	WALK_SPEED *= velocidad_random
	RUN_SPEED *= velocidad_random

	aparecer()

# =========================================================
# APARECER
# =========================================================

func aparecer():

	estado = Estado.EMERGIENDO

	emergiendo = true

	animated_sprite_2d.visible = true

	velocity = Vector2.ZERO

	await get_tree().create_timer(0.5).timeout

	emergiendo = false

	estado = Estado.PERSEGUIR

	puede_moverse = true
	puede_atacar = true

# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta):
	if vida <= 0:
		return

	# UI VIDA
	if vida_etiqueta:
		vida_etiqueta.global_position = global_position + Vector2(-25, -75)

	if vida_bar:
		vida_bar.global_position = global_position + Vector2(-40, -55)

	# ESCONDIDO
	if estado == Estado.ESCONDIDO:
		return

	# EMERGIENDO
	if emergiendo:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# HUYENDO
	if estado == Estado.HUYENDO:

		navigation_agent.target_position = punto_escape + offset_movimiento

		if not navigation_agent.is_navigation_finished():

			var next_pos = navigation_agent.get_next_path_position()
			var dir = global_position.direction_to(next_pos)

			velocity = dir * velocidad_huida

			# 🔥 FORZAR ANIMACIÓN SOLO MOVER
			if animated_sprite_2d.animation != "Mover":
				animated_sprite_2d.play("Mover")

			if velocity.x != 0:
				animated_sprite_2d.flip_h = velocity.x < 0

			move_and_slide()

		else:
			desaparecer()

		return

	# IA NORMAL (PERSEGUIR)
	if player and estado == Estado.PERSEGUIR:

		var distancia := global_position.distance_to(player.global_position)

		# 🔥 EVITA PEGARSE AL JUGADOR
		if distancia <= rango_ataque:
			# 🔥 NO lo congeles
			# solo deja de recalcular path agresivo
			navigation_agent.target_position = global_position

			# deja que EnemyBase controle el ataque sin interferencia
		else:
			navigation_agent.target_position = player.global_position + offset_movimiento

		super._physics_process(delta)
# =========================================================
# RECIBIR DAÑO
# =========================================================

func recibir_daño(cantidad: int) -> void:

	if estado == Estado.ESCONDIDO:
		return

	if estado == Estado.EMERGIENDO:
		return

	super.recibir_daño(cantidad)

	# 🔥 Si murió, no puede huir
	if vida <= 0:
		morir()
		return

	var limite_huida := vida_max * porcentaje_huida

	if estado != Estado.HUYENDO and vida <= limite_huida:
		estado = Estado.HUYENDO

		puede_moverse = false
		puede_atacar = false

		punto_escape = spawner_ref.obtener_esquina_escape(id_sabueso)

# =========================================================
# DESAPARECER
# =========================================================

func desaparecer():
	if vida <= 0:
		return
	estado = Estado.ESCONDIDO

	set_physics_process(false)
	set_process(false)

	velocity = Vector2.ZERO
	navigation_agent.set_velocity(Vector2.ZERO)

	animated_sprite_2d.visible = false
	vida_bar.visible = false
	vida_etiqueta.visible = false

	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true

	puede_moverse = false
	puede_atacar = false

	if spawner_ref:
		spawner_ref.sabueso_escondido(id_sabueso, vida)

	queue_free()
# =========================================================
# MUERTE
# =========================================================

func morir() -> void:

	if spawner_ref:

		spawner_ref.sabueso_escondido(
			id_sabueso,
			0
		)

	super.morir()
