extends Node2D

@export var mine_scene: PackedScene
@export var spawn_point: Node2D
@export var facing_node: Node2D

@export var use_cooldown := 10.0

var cooldown_timer := 0.0

var move_input := Vector2.ZERO


func _ready():
	print("Spawner listo")


func _process(delta):

	# =========================================
	# BAJAR COOLDOWN
	# =========================================
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# =========================================
	# INPUT
	# =========================================
	if Input.is_action_just_pressed("place_mine"):

		if cooldown_timer <= 0:

			print("TECLA BOMBA")

			try_place_mine()


func try_place_mine():

	print("Intentando colocar mina...")

	if mine_scene == null:
		return

	if spawn_point == null:
		return

	var dir := Vector2.RIGHT

	if move_input.length() > 0.01:
		dir = move_input.normalized()

	elif facing_node:
		dir = Vector2(sign(facing_node.scale.x), 0)

	var mine = mine_scene.instantiate()

	get_tree().current_scene.add_child(mine)

	mine.launch(dir, spawn_point.global_position)

	cooldown_timer = use_cooldown

	print("MINA COLOCADA")
