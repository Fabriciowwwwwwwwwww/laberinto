extends CharacterBody2D

@export var xp_value: int = 5
@export var ulti_charge_value: float = 5.0

@export var attract_distance: float = 100.0
@export var attract_speed: float = 120.0

@export var expansion_speed: float = 2.0
@export var expansion_time: float = 2
@export var lifetime: float = 10.0

var player: Node2D

var direction: Vector2
var estado := "expandiendo"
var timer := 0.0

func _ready():
	add_to_group("xp_orb")
	player = get_tree().get_first_node_in_group("player")

	# Dirección aleatoria suave
	var angle = randf_range(0, TAU)
	direction = Vector2(cos(angle), sin(angle)).normalized()

	# Destruir después de tiempo
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	if player == null:
		return

	timer += delta

	# ------------------ ESTADO 1: EXPANSIÓN ------------------
	if estado == "expandiendo":
		velocity = direction * expansion_speed

	elif estado == "libre":
		velocity = velocity.lerp(Vector2.ZERO, 0.08)

	elif estado == "atrayendo":
		var dir = (player.global_position - global_position).normalized()
		velocity = velocity.lerp(dir * attract_speed, 0.08)

	move_and_slide()
func _on_area_2d_body_entered(body):
	if not body.is_in_group("player"):
		return

	if body.has_method("agregar_experiencia"):
		body.agregar_experiencia(xp_value)

	var ult = body.get_node_or_null("UltimateWeapon")
	if ult and ult.has_method("add_charge"):
		ult.add_charge(ulti_charge_value)

	queue_free() # 💥 aquí desaparece
