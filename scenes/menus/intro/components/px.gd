extends CharacterBody2D

@export var xp_value: int = 5
@export var ulti_charge_value: float = 5.0

# ATRACCIÓN
@export var attract_distance: float = 140.0
@export var attract_speed: float = 280.0

# EXPLOSIÓN AL SALIR
@export var expansion_speed: float = 180.0
@export var expansion_time: float = 0.35

# VIDA
@export var lifetime: float = 10.0

# FRENADO
@export var friction: float = 450.0

var player: Node2D

var direction: Vector2
var estado := "expandiendo"
var timer := 0.0

func _ready():

	add_to_group("xp_orb")

	player = get_tree().get_first_node_in_group("player")

	# dirección aleatoria
	var angle = randf_range(0, TAU)

	# 🔥 radio controlado (evita explosiones exageradas)
	var radius = randf_range(0.2, 1.0)

	direction = Vector2(cos(angle), sin(angle)) * radius
	direction = direction.normalized()

	# impulso inicial
	var speed_variation = randf_range(0.75, 1.15)
	velocity = direction * expansion_speed * speed_variation

	# destruir luego
	await get_tree().create_timer(lifetime).timeout

	if is_instance_valid(self):
		queue_free()


func _physics_process(delta):

	if player == null:
		return

	timer += delta

	# DISTANCIA AL JUGADOR
	var distance = global_position.distance_to(player.global_position)

	# -------------------------
	# ESTADO EXPANDIENDO
	# -------------------------
	if estado == "expandiendo":

		# freno gradual
		velocity = velocity.lerp(Vector2.ZERO, 6.0 * delta)

		# termina expansión
		if timer >= expansion_time:
			estado = "libre"

	# -------------------------
	# ESTADO LIBRE
	# -------------------------
	elif estado == "libre":

		# si jugador se acerca
		if distance <= attract_distance:
			estado = "atrayendo"

	# -------------------------
	# ESTADO ATRAYENDO
	# -------------------------
	elif estado == "atrayendo":

		# dirección al jugador
		var dir = global_position.direction_to(player.global_position)

		# movimiento suave
		velocity = velocity.move_toward(
			dir * attract_speed,
			900 * delta
		)

	move_and_slide()


func _on_area_2d_body_entered(body):

	if not body.is_in_group("player"):
		return

	# XP
	if body.has_method("agregar_experiencia"):
		body.agregar_experiencia(xp_value)

	# Ultimate
	var ult = body.get_node_or_null("UltimateWeapon")

	if ult and ult.has_method("add_charge"):
		ult.add_charge(ulti_charge_value)

	queue_free()
