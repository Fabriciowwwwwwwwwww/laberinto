extends Area2D

@export var explosion_radius := 100.0
@export var base_damage := 30.0
@export var knockback_force := 200.0
@export var arm_time := 0.6
@export var lifetime: float = 3

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = get_node_or_null("colision")

var is_active := false
var is_armed := false
var arm_timer := 0.0


func _ready()-> void:
	visible = false
	set_physics_process(false)

	if collision:
		collision.disabled = true
	else:
		print("❌ NO se encontró colision (nombre mal?)")



func launch(dir: Vector2, pos: Vector2) -> void:
	global_position = pos

	is_active = true
	is_armed = false
	arm_timer = 0

	visible = true
	set_physics_process(true)

	if collision:
		collision.disabled = false

	if visual:
		visual.play("idle")

	# Empieza a contar desde que se lanza
	await get_tree().create_timer(lifetime).timeout

	if is_active:
		print("⏰ Tiempo agotado")
		explode()



func _physics_process(delta)-> void:
	if not is_active:
		return

	if not is_armed:
		arm_timer += delta
		if arm_timer >= arm_time:
			is_armed = true
			print("💣 Mina ARMADA")



func _on_body_entered(body)-> void:
	if not is_active or not is_armed:
		return

	if body.is_in_group("enemigos") or body.is_in_group("enemy"):
		print("🔥 EXPLOTA")
		explode()


func explode()-> void:
	print("💥 EXPLOSIÓN")

	is_active = false

	for enemy in get_tree().get_nodes_in_group("enemigos"):
		var dist = enemy.global_position.distance_to(global_position)

		if dist <= explosion_radius:
			print("Golpeando enemigo:", enemy.name)

			if enemy.has_method("recibir_daño"):
				enemy.recibir_daño(base_damage)

	if visual:
		visual.play("explosion")

		if not visual.animation_finished.is_connected(_reset):
			visual.animation_finished.connect(_reset, CONNECT_ONE_SHOT)
	else:
		_reset()


func _reset()-> void:
	print("♻️ Mina eliminada")
	queue_free()
