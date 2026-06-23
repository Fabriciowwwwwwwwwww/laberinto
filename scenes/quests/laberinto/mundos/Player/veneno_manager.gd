extends Node2D

@export var poison_area_scene: PackedScene
@export var cooldown := 10.0
var poison_target := Vector2.ZERO
var ultima_direccion_poison := Vector2.RIGHT
var cooldown_timer := 0.0

var poison_preview: Node2D = null
var selecting_poison := false


func _physics_process(delta):

	# =========================================
	# BAJAR COOLDOWN
	# =========================================
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# =========================================
	# ACTIVAR SELECCIÓN
	# =========================================
	if Input.is_action_just_pressed("area_veneno"):

		if cooldown_timer <= 0 and not selecting_poison:

			selecting_poison = true

			var player = get_tree().get_first_node_in_group("player")

			if player:
				poison_target = player.global_position

			poison_preview = Node2D.new()

			var sprite := Sprite2D.new()

			sprite.texture = preload("res://scenes/quests/laberinto/sprite_laberinto/arma player sprite/Items/Bottle.png")

			sprite.modulate = Color(0.3, 0.8, 1.0, 0.4)
			sprite.scale = Vector2(1.5, 1.5)
			sprite.centered = true

			poison_preview.add_child(sprite)

			get_tree().current_scene.add_child(poison_preview)

			print("[VENENO] Selección iniciada")

	# =========================================
	# MOVER PREVIEW
	# =========================================
# =========================================
# MOVER PREVIEW
# =========================================
	if selecting_poison and poison_preview:

		var player = get_tree().get_first_node_in_group("player")

		var stick := Vector2(
			Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		)

		var velocidad_cursor := 500.0
		var distancia_maxima := 250.0

		# 🎮 GAMEPAD
		if stick.length() > 0.2:

			poison_target += stick.normalized() * velocidad_cursor * delta

		# 🖱️ MOUSE
		elif Input.get_connected_joypads().is_empty():

			poison_target = get_global_mouse_position()

		# 🔒 Limitar distancia al jugador
		if player:

			var offset = poison_target - player.global_position

			if offset.length() > distancia_maxima:
				offset = offset.normalized() * distancia_maxima

			poison_target = player.global_position + offset

		poison_preview.global_position = poison_target

		# =========================================
		# COLOCAR VENENO
		# =========================================
		if Input.is_action_just_pressed("veneno_activo"):

			var poison_instance = poison_area_scene.instantiate()

			get_tree().current_scene.add_child(poison_instance)

			poison_instance.global_position = poison_preview.global_position

			poison_preview.queue_free()
			poison_preview = null

			selecting_poison = false
			cooldown_timer = cooldown

			print("[VENENO] Área colocada")
