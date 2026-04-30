extends Area2D
@export var travel_duration := 0.35
@export var travel_distance := 10.0
@export var arc_height := 20.0
@export var max_lifetime := 25.0

@export var arm_time := 0.6
@export var explosion_radius := 80.0
@export var base_damage := 12.0
@export var knockback_force := 200.0

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D

var life_timer := 0.0
var travel_timer := 0.0
var arm_timer := 0.0

var is_moving := false
var is_armed := false
var has_landed := false
var is_exploding := false

var move_dir := Vector2.ZERO
var start_pos := Vector2.ZERO
var base_visual_pos := Vector2.ZERO


func _ready():
	monitoring = true
	connect("body_entered", _on_body_entered)

	if visual:
		base_visual_pos = visual.position
		visual.play("idle") # 🔥 inicia en idle


func launch(dir: Vector2, world_start_pos: Vector2):
	global_position = world_start_pos
	start_pos = world_start_pos

	move_dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT

	life_timer = 0
	travel_timer = 0
	arm_timer = 0

	is_moving = true
	has_landed = false
	is_armed = false
	is_exploding = false

	if visual:
		visual.position = base_visual_pos
		visual.play("idle")


func _process(delta):
	if is_exploding:
		return

	life_timer += delta

	# Movimiento en arco
	if is_moving:
		travel_timer += delta
		var t = clamp(travel_timer / travel_duration, 0.0, 1.0)

		var plane_pos = start_pos + move_dir * (travel_distance * t)
		var h = 4.0 * arc_height * t * (1.0 - t)

		global_position = plane_pos

		if visual:
			visual.position = base_visual_pos + Vector2(0, -h)

		if t >= 1.0:
			is_moving = false
			has_landed = true
			if visual:
				visual.position = base_visual_pos

	# Armado
	if has_landed and not is_armed:
		arm_timer += delta
		if arm_timer >= arm_time:
			is_armed = true

	# Vida máxima
	if life_timer >= max_lifetime:
		queue_free()


func _on_body_entered(body):
	print("COLISION CON:", body.name, " grupos:", body.get_groups())

	if body.is_in_group("enemigos"):
		print("ES ENEMIGO 🔥")
		explode()


func explode():
	if is_exploding:
		return

	is_exploding = true
	monitoring = false # 🔥 evita múltiples triggers

	# 💥 daño inmediato
	var space = get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius

	query.shape = shape
	query.transform = Transform2D(0, global_position)

	var results = space.intersect_shape(query)

	for r in results:
		var obj = r.collider

		if obj.is_in_group("enemigos"):
			if obj.has_method("recibir_daño"):
				obj.recibir_daño(base_damage)

			if obj is CharacterBody2D:
				var dir = (obj.global_position - global_position).normalized()
				obj.velocity += dir * knockback_force

	# 🎬 reproducir animación
	if visual:
		visual.play("explosion")
		visual.animation_finished.connect(_on_explosion_finished)
	else:
		queue_free()


func _on_explosion_finished():
	queue_free()
