extends Node2D

@export var mine_scene: PackedScene
@export var spawn_point: Node2D
@export var facing_node: Node2D
@export var use_cooldown := 1.0
var cooldown_timer := 0.0
@export var max_mines := 3
@export var replenish_interval := 8.0

var current_mines := 0
var replenish_timer := 0.0

var move_input := Vector2.ZERO  # conéctalo a tu player


func _ready():
	current_mines = max_mines


func _process(delta):
	cooldown_timer -= delta
	# recarga automática
	if current_mines < max_mines:
		replenish_timer += delta
		if replenish_timer >= replenish_interval:
			replenish_timer = 0
			current_mines += 1

	# 🎮 colocar mina
	if Input.is_action_just_pressed("place_mine") and cooldown_timer <= 0:
		try_place_mine()
		cooldown_timer = use_cooldown

func try_place_mine():
	if current_mines <= 0:
		return
	if mine_scene == null or spawn_point == null:
		return

	var dir = Vector2.ZERO

	if move_input.length() > 0.01:
		dir = move_input.normalized()
	elif facing_node:
		dir = Vector2(sign(facing_node.scale.x), 0)
	else:
		dir = Vector2.RIGHT

	var mine = mine_scene.instantiate()
	get_tree().current_scene.add_child(mine)

	mine.launch(dir, spawn_point.global_position)

	current_mines -= 1
