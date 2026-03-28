extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var sonido: AudioStreamPlayer2D = $golpe
@onready var idle_sonido: AudioStreamPlayer2D = $idle
@export var WALK_SPEED: float = 200.0
@export var RUN_SPEED: float = 350.0
@export var run_duration: float = 2.0
@export var walk_duration: float = 4.0
@export var rango_ataque: float = 90.0
@export var dano: int = 10
@export var tiempo_entre_ataques: float = 0.8

var puede_atacar: bool = true
var animacion_bloqueada: bool = false
var vida: int = 50
var puede_moverse: bool = true
var current_speed: float
var last_direction: Vector2 = Vector2.DOWN
var player: Node2D
var path_update_timer: float = 0.0
const PATH_UPDATE_INTERVAL: float = 0.2
var run_timer: float = 0.0
var is_running: bool = false

func _ready() -> void:
	sonido.bus = "SFX"
	idle_sonido.bus = "SFX"
	current_speed = WALK_SPEED
	idle_sonido.play()
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 16.0
	navigation_agent.max_speed = RUN_SPEED

	setup_dust_particles()
	call_deferred("setup_navigation")

func recibir_daño(cantidad: int) -> void:
	vida -= cantidad
	puede_moverse = false
	
	if vida <= 0:
		queue_free()
		remove_from_group("enemigos")
	
	navigation_agent.set_velocity(Vector2.ZERO)
	animated_sprite_2d.play("golpeado")
	
	await get_tree().create_timer(0.3).timeout
	puede_moverse = true

# ------------------ PARTÍCULAS ------------------

func setup_dust_particles() -> void:
	if not dust_particles:
		dust_particles = GPUParticles2D.new()
		add_child(dust_particles)

	dust_particles.emitting = false
	dust_particles.amount = 15
	dust_particles.lifetime = 0.8
	dust_particles.position = Vector2(0, 10)

	var particle_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 40.0
	particle_material.gravity = Vector3(0, 50, 0)
	particle_material.scale_min = 0.3
	particle_material.scale_max = 0.7
	#particle_material.color_ramp = create_dust_gradient()

	dust_particles.process_material = particle_material
	dust_particles.texture = create_dust_texture()

func create_dust_gradient() -> Gradient:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.8, 0.7, 0.5, 0.8),
		Color(0.6, 0.5, 0.3, 0.4),
		Color(0.4, 0.3, 0.2, 0.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	return gradient

func create_dust_texture() -> ImageTexture:
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(4, 4)

	for x in range(8):
		for y in range(8):
			var distance: float = Vector2(x, y).distance_to(center)
			var alpha: float = max(0.0, 1.0 - (distance / 4.0))
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	var texture: ImageTexture = ImageTexture.new()
	texture.set_image(image)
	return texture

# ------------------ IA ------------------

func setup_navigation() -> void:
	await get_tree().physics_frame
	
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		navigation_agent.target_position = player.global_position
		player.connect("jugador_derrotado", Callable(self, "_on_jugador_muerto"))

	if not navigation_agent.velocity_computed.is_connected(_on_velocity_computed):
		navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
	if not puede_moverse:
		velocity = Vector2.ZERO
		handle_animations(Vector2.ZERO)
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			queue_free()
			return

	intentar_atacar()
	update_speed(delta)
	navigation_agent.max_speed = current_speed
	
	path_update_timer += delta
	if path_update_timer >= PATH_UPDATE_INTERVAL:
		path_update_timer = 0.0
		navigation_agent.target_position = player.global_position

	if not navigation_agent.is_navigation_finished():
		var next_pos: Vector2 = navigation_agent.get_next_path_position()
		var direction: Vector2 = global_position.direction_to(next_pos)
		
		var desired_velocity: Vector2 = direction * current_speed
		navigation_agent.set_velocity(desired_velocity)
		
		handle_animations(direction)
	else:
		velocity = Vector2.ZERO
		handle_animations(Vector2.ZERO)

	update_dust_particles()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

# ------------------ MOVIMIENTO ------------------

func update_speed(delta: float) -> void:
	run_timer += delta
	
	if is_running:
		current_speed = RUN_SPEED
		if run_timer >= run_duration:
			is_running = false
			run_timer = 0.0
	else:
		current_speed = WALK_SPEED
		if run_timer >= walk_duration:
			is_running = true
			run_timer = 0.0

func update_dust_particles() -> void:
	if dust_particles:
		dust_particles.emitting = is_running and velocity.length() > 10.0

# ------------------ ANIMACIONES ------------------

func handle_animations(movement_vector: Vector2) -> void:
	if animacion_bloqueada:
		return

	if movement_vector != Vector2.ZERO:
		last_direction = movement_vector

	var is_moving: bool = velocity.length() > 5.0

	if is_moving:
		# 🔥 NUEVA LÓGICA: subir
		if abs(movement_vector.y) > abs(movement_vector.x):
			if movement_vector.y < 0:
				animated_sprite_2d.play("subir") # 👈 NUEVO
			else:
				animated_sprite_2d.play("Mover")
		else:
			animated_sprite_2d.flip_h = movement_vector.x < 0
			animated_sprite_2d.play("Mover")
	else:
		animated_sprite_2d.stop()

# ------------------ ATAQUE ------------------

func intentar_atacar() -> void:
	if not puede_atacar or not player:
		return

	if global_position.distance_to(player.global_position) <= rango_ataque:
		sonido.play()
		puede_atacar = false
		puede_moverse = false
		animacion_bloqueada = true

		animated_sprite_2d.play("ataque")

		if player.has_method("recibir_daño"):
			player.recibir_daño(dano)

		if not await await_tiempo_seguro(0.5):
			return

		animacion_bloqueada = false
		puede_moverse = true

		if not await await_tiempo_seguro(tiempo_entre_ataques - 0.5):
			return

		puede_atacar = true

func await_tiempo_seguro(segundos: float) -> bool:
	if not is_inside_tree():
		return false
	var timer: SceneTreeTimer = get_tree().create_timer(segundos)
	await timer.timeout
	return is_inside_tree()

func _on_jugador_muerto() -> void:
	queue_free()
