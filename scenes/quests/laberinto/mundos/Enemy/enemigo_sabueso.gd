extends EnemyBase

enum Estado {
	ESPERANDO,
	EMERGIENDO,
	PERSEGUIR,
	HUYENDO,
	ESCONDIDO
}

var estado = Estado.ESPERANDO

var activado := false
var emergiendo := false

var esquina_origen: Vector2

@export var velocidad_huida := 520.0
@export var tiempo_reaparicion := 6.0

# ==================================================
# READY
# ==================================================

func _ready():

	add_to_group("enemigos")
	add_to_group("sabuesos")

	super()

	esquina_origen = global_position

	# oculto al inicio
	if animated_sprite_2d:
		animated_sprite_2d.visible = false

	# desactivar IA base
	puede_moverse = false
	puede_atacar = false

	# pequeña espera para asegurar player/navigation
	await get_tree().create_timer(0.2).timeout

	activado = true

	aparecer()

# ==================================================
# APARECER
# ==================================================

func aparecer():

	if not animated_sprite_2d:
		return

	estado = Estado.EMERGIENDO

	emergiendo = true

	animated_sprite_2d.visible = true

	velocity = Vector2.ZERO

	# efecto dramático
	await get_tree().create_timer(0.5).timeout

	emergiendo = false

	estado = Estado.PERSEGUIR

	# activar IA EnemyBase
	puede_moverse = true
	puede_atacar = true

# ==================================================
# PHYSICS
# ==================================================

func _physics_process(delta):

	# escondido
	if estado == Estado.ESCONDIDO:
		return

	# emergiendo
	if emergiendo:

		velocity = Vector2.ZERO

		move_and_slide()

		return

	# HUIR
	if estado == Estado.HUYENDO:

		var dir = (
			esquina_origen - global_position
		).normalized()

		velocity = dir * velocidad_huida

		move_and_slide()

		# flip sprite
		if animated_sprite_2d:

			if velocity.x != 0:
				animated_sprite_2d.flip_h = velocity.x < 0

		# llegó a esquina
		if global_position.distance_to(
			esquina_origen
		) < 20:

			desaparecer()

		return

	# IA NORMAL DEL ENEMYBASE
	super._physics_process(delta)

# ==================================================
# RECIBIR DAÑO
# ==================================================

func recibir_daño(cantidad: int) -> void:

	# ya huyendo
	if estado == Estado.HUYENDO:
		return

	super.recibir_daño(cantidad)

	# sobrevivió -> huir
	if vida > 0:

		estado = Estado.HUYENDO

		puede_moverse = false
		puede_atacar = false

# ==================================================
# DESAPARECER
# ==================================================

func desaparecer():

	estado = Estado.ESCONDIDO

	velocity = Vector2.ZERO

	if animated_sprite_2d:
		animated_sprite_2d.visible = false

	puede_moverse = false
	puede_atacar = false

	# esperar reaparición
	await get_tree().create_timer(
		tiempo_reaparicion
	).timeout

	# restaurar vida
	vida = vida_max

	# volver a activar
	estado = Estado.PERSEGUIR

	if animated_sprite_2d:
		animated_sprite_2d.visible = true

	puede_moverse = true
	puede_atacar = true

# ==================================================
# MUERTE
# ==================================================

func morir() -> void:

	super.morir()
