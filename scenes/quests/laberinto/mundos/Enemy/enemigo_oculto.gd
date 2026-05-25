extends EnemyBase

@onready var area_activacion: Area2D = $AreaActivacion

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
var huyendo := false

var esquina_origen: Vector2

@export var velocidad_huida := 500.0
@export var tiempo_reaparicion := 6.0

# ==================================================
# READY
# ==================================================

func _ready():

	add_to_group("enemigos")
	add_to_group("sabuesos")

	super()

	esquina_origen = global_position

	animated_sprite_2d.visible = false

	area_activacion.body_entered.connect(_on_body_entered)

# ==================================================
# ACTIVACION
# ==================================================

func _on_body_entered(body):

	if activado:
		return

	if not body.is_in_group("player"):
		return

	activado = true

	aparecer()

# ==================================================
# APARECER
# ==================================================

func aparecer():

	estado = Estado.EMERGIENDO

	emergiendo = true

	animated_sprite_2d.visible = true

	velocity = Vector2.ZERO

	animated_sprite_2d.play("Mover")

	await animated_sprite_2d.animation_finished

	emergiendo = false

	estado = Estado.PERSEGUIR

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

		animated_sprite_2d.play("Mover")

		if velocity.x != 0:
			animated_sprite_2d.flip_h = velocity.x < 0

		# llegó a la esquina
		if global_position.distance_to(esquina_origen) < 15:

			desaparecer()

		return

	# IA NORMAL
	super._physics_process(delta)

# ==================================================
# RECIBIR DAÑO
# ==================================================

func recibir_daño(cantidad: int) -> void:

	# si ya huye no repetir
	if estado == Estado.HUYENDO:
		return

	super.recibir_daño(cantidad)

	# sobrevivió -> huir
	if vida > 0:

		huyendo = true

		estado = Estado.HUYENDO

		puede_atacar = false

		# más rápido al huir
		current_speed = velocidad_huida

# ==================================================
# DESAPARECER
# ==================================================

func desaparecer():

	estado = Estado.ESCONDIDO

	velocity = Vector2.ZERO

	animated_sprite_2d.visible = false

	await get_tree().create_timer(
		tiempo_reaparicion
	).timeout

	# restaurar comportamiento
	huyendo = false

	activado = false

	estado = Estado.ESPERANDO

	# reaparecer con vida recuperada
	vida = vida_max

	# volver a activar detección
	area_activacion.monitoring = true

# ==================================================
# MUERTE
# ==================================================

func morir() -> void:

	super.morir()
