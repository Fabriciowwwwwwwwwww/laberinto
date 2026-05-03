extends Node2D

@export var mine_scene: PackedScene
@export var spawn_point: Node2D
@export var facing_node: Node2D

@export var use_cooldown := 1.0
@export var max_mines := 3
@export var replenish_interval := 8.0

var cooldown_timer := 0.0
var current_mines := 0
var replenish_timer := 0.0

var move_input := Vector2.ZERO


func _ready():
	print("Spawner listo")
	current_mines = max_mines


func _process(delta):
	cooldown_timer -= delta

	# recarga
	if current_mines < max_mines:
		replenish_timer += delta
		if replenish_timer >= replenish_interval:
			replenish_timer = 0
			current_mines += 1
			print("Recargó mina. Total:", current_mines)

	# 🔥 TEST INPUT
	if Input.is_action_just_pressed("place_mine"):
		print("TECLA E DETECTADA")
		if cooldown_timer <= 0:
			try_place_mine()
			cooldown_timer = use_cooldown


func try_place_mine():
	print("Intentando colocar mina...")

	if current_mines <= 0:
		print("❌ SIN MINAS")
		return

	if mine_scene == null:
		print("❌ mine_scene es NULL")
		return

	if spawn_point == null:
		print("❌ spawn_point es NULL")
		return

	print("✔ mine_scene OK")
	print("✔ spawn_point:", spawn_point)
	print("✔ posición spawn:", spawn_point.global_position)

	var dir := Vector2.RIGHT

	if move_input.length() > 0.01:
		dir = move_input.normalized()
	elif facing_node:
		dir = Vector2(sign(facing_node.scale.x), 0)

	print("Dirección:", dir)

	var mine = mine_scene.instantiate()

	if mine == null:
		print("❌ NO SE PUDO INSTANCIAR LA MINA")
		return

	print("✔ Mina instanciada:", mine)

	get_tree().current_scene.add_child(mine)

	print("✔ Mina añadida al árbol")

	mine.launch(dir, spawn_point.global_position)

	print("✔ launch ejecutado")

	current_mines -= 1
	print("Minas restantes:", current_mines)
