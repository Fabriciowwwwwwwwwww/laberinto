extends CharacterBody2D

signal damage(value: float)
signal died
var madness_chasing := false
var dash_damage := 30
# ----------------- ESTRUCTURA DE FASES -----------------
enum State {
	READY_GO,         # Entrada/Bloqueo
	CHASE_1,          # 0s -> 6s (Caza lenta)
	RANGED_ATTACK,    # 7s -> 13s (LeftAttack + Zonas peligrosas)
	CHASE_2,          # 13s -> 18s (Caza rápida)
	TRANSITION_F2,    # Cambiando a Fase 2 (66% HP)
	BULLET_HELL,      # 20s -> 35s (CenterAttack + Espiral dinámico)
	TRANSITION_F3,    # Cambiando a Fase 3 (33% HP)
	MADNESS,          # Fase 3 (RightAttack/Dash horizontal + Esbirros)
	FINAL_DESPERATION # Último 10% (Caos controlado lento)
}

var current_state: int = State.READY_GO

# --- Referencias de la escena ---
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var bar_boss: ProgressBar = $ProgressBar_boss
@onready var label: Label = $Label
@onready var area: Area2D = $Area2D
@onready var sfx_hit: AudioStreamPlayer2D = $hit
@onready var explosion_timer: Timer = $explosion_timer
@onready var punch_timer: Timer = $Punch_timer
@export var minion_2: PackedScene
# --- Puntos de Ataque (Cargados desde la escena) ---
@onready var left_attack = $"../AttackPoints/LeftAttack"
@onready var center_attack = $"../AttackPoints/CenterAttack"
@onready var right_attack = $"../AttackPoints/RightAttack"

# --- Escenas exportadas ---
@export var bullet_scene: PackedScene
@export var danger_zone_scene: PackedScene # Asigna un círculo de advertencia que explote
@export var minion_scene: PackedScene      # Asigna el enemigo volador de la Fase 3

# --- Configuración de Movimiento ---
var speed := 80.0
var _base_speed := 80.0
var accel := 1600.0
var face_sign := 1.0

# Oscilación estética
var walk_freq := 1.4
var walk_phase := 0.0
var up_freq := 1.8
var walk_seed := 0.0
var side_amp := 20.0
var up_amp := 10.0

# --- Timers de Fase internos ---
var phase_timer := 0.0
var attack_cooldown_timer := 0.0
var sub_pattern_timer := 0.0

# --- Control de Habilidades ---
var player: CharacterBody2D = null
var dead := false
var reported_dead := false
var target_in_range: CharacterBody2D = null
var _attack_lock := false
var spiral_angle := 0.0
var target_position := Vector2.ZERO

# --- Control de Vida y Daño (Sincronizado con EnemyBase) ---
@export var vida: int = 600          # Ajusta la vida base que quieras desde el Inspector
var vida_max: int = 600
var en_cooldown_golpe := false
var timer_golpe: Timer

# Registro de fases cruzadas por HP para no repetir transiciones
var _f2_triggered := false
var _f3_triggered := false
var _desperation_triggered := false

# Daño flotante (Stack acumulativo)
var _stack_value := 0.0
var _label_base_pos := Vector2.ZERO
var _tween: Tween
var _stack_timer: Timer

func _ready() -> void:
	# Capturar jugador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	add_to_group("boss")

	_label_base_pos = label.position
	label.visible = false
	
	randomize()
	walk_seed = randf() * TAU

	# Sincronizar variables de vida con la ProgressBar
	vida_max = vida
	if bar_boss:
		bar_boss.max_value = vida_max
		bar_boss.value = vida

	# Conexiones seguras de colisiones
	area.monitoring = true
	if not area.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	if not area.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		area.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))

	# Inicializar temporizador de golpes físicos
	punch_timer.one_shot = true

	# Configurar el Timer estructural de golpe (Idéntico a tu EnemyBase)
	timer_golpe = Timer.new()
	timer_golpe.one_shot = true
	timer_golpe.wait_time = 0.3
	add_child(timer_golpe)
	timer_golpe.timeout.connect(_fin_golpe)

	# Configurar timer de acumulación de números de daño
	_stack_timer = Timer.new()
	_stack_timer.one_shot = true
	add_child(_stack_timer)
	_stack_timer.connect("timeout", func(): 
		_stack_value = 0.0
		label.visible = false
	)

	# Bloquear jugador al inicio para la secuencia Ready-Set-Go
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(false)

	# Iniciar el cronograma del combate
	current_state = State.READY_GO
	phase_timer = 0.0

func _physics_process(delta: float) -> void:
	for i in range(get_slide_collision_count()):

		var collision = get_slide_collision(i)

		if collision:

			var collider = collision.get_collider()

			if collider and collider.is_in_group("player"):

				global_position -= collision.get_normal() * 4.0
	if dead or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := Vector2.ZERO
	if dist > 0.0:
		dir = to_player / dist

	# --- MÁQUINA DE ESTADOS Y CONTROL DE TIEMPO ---
	phase_timer += delta
	_process_states(delta, dist, dir)

	# --- ROTACIÓN / DIRECCIÓN VISUAL ---
	if current_state != State.READY_GO and current_state != State.TRANSITION_F2 and current_state != State.TRANSITION_F3:
		if abs(dir.x) > 0.1:
			face_sign = sign(dir.x)
		sprite_2d.flip_h = face_sign < 0.0

	move_and_slide()

# ----------------- LÓGICA DE COMPORTAMIENTOS -----------------
func _process_states(delta: float, dist: float, dir: Vector2) -> void:
	# Comprobaciones de Vida (Cambios de fase prioritarios basados en % real)
	var hp_pct = _hp_pct()
	if hp_pct <= 0.10 and not _desperation_triggered and current_state == State.MADNESS:
		_enter_desperation_mode()
		return
	elif hp_pct <= 0.33 and not _f3_triggered and current_state == State.BULLET_HELL:
		_trigger_transition_f3()
		return
	elif hp_pct <= 0.66 and not _f2_triggered and (current_state == State.CHASE_1 or current_state == State.RANGED_ATTACK or current_state == State.CHASE_2):
		_trigger_transition_f2()
		return

	match current_state:
		State.READY_GO:
			velocity = Vector2.ZERO
			if phase_timer >= 1.5:
				if player and player.has_method("set_physics_process"):
					player.set_physics_process(true)
				current_state = State.CHASE_1
				phase_timer = 0.0

		State.CHASE_1:

			speed = _base_speed

			_apply_oscillating_movement(
				delta,
				dir,
				dist,
				140.0,
				70.0
			)

			attack_cooldown_timer += delta

			# dispara mucho más rápido
			if attack_cooldown_timer >= 0.45:

				attack_cooldown_timer = 0.0

				if not _attack_lock:
					_shoot_burst_attack(dir)

			# invocar minions durante la persecución
			sub_pattern_timer += delta

			if sub_pattern_timer >= 6.0:

				sub_pattern_timer = 0.0

				_spawn_flying_minion()

			if dist <= 80.0 and punch_timer.time_left <= 0.0:
				_do_melee_punch(dir)

			if phase_timer >= 4.0:

				current_state = State.RANGED_ATTACK

				phase_timer = 0.0

				sub_pattern_timer = 0.0

				attack_cooldown_timer = 0.0

		State.RANGED_ATTACK:

			if left_attack:
				_move_to_marker_safely(
					left_attack.global_position,
					delta,
					1.8
				)
			else:
				velocity = Vector2.ZERO

			# =====================================================
			# DISPAROS EN RÁFAGAS CONTROLADAS
			# =====================================================

			attack_cooldown_timer += delta

			# SOLO si no está disparando actualmente
			if attack_cooldown_timer >= 2.8 and not _attack_lock:

				attack_cooldown_timer = 0.0

				_shoot_burst_attack(dir)

			# =====================================================
			# ZONAS PELIGROSAS
			# =====================================================

			sub_pattern_timer += delta

			if sub_pattern_timer >= 1.8:

				sub_pattern_timer = 0.0

				_spawn_danger_zone()

			# transición más rápida
			if phase_timer >= 4.5:

				current_state = State.CHASE_2

				phase_timer = 0.0

		State.CHASE_2:
			attack_cooldown_timer += delta
			if attack_cooldown_timer >= 0.8:
				attack_cooldown_timer = 0.0
				if not _attack_lock:
					_shoot_burst_attack(dir)
			speed = _base_speed * 1.3
			_apply_oscillating_movement(delta, dir, dist, 160.0, 50.0)
			if dist <= 80.0 and punch_timer.time_left <= 0.0:
				_do_melee_punch(dir)

			if phase_timer >= 5.0:
				current_state = State.CHASE_1
				phase_timer = 0.0

		State.TRANSITION_F2:
			velocity = Vector2.ZERO
			if phase_timer >= 2.0:
				current_state = State.BULLET_HELL
				phase_timer = 0.0
				attack_cooldown_timer = 0.0
				sub_pattern_timer = 0.0

		State.BULLET_HELL:
			if center_attack:
				_move_to_marker_safely(center_attack.global_position, delta, 0.7)
			else:
				velocity = Vector2.ZERO

			# =====================================================
			# 🌪️ OLEADAS GRANDES
			# =====================================================
			attack_cooldown_timer += delta

			# MUCHÍSIMO descanso entre oleadas
			if attack_cooldown_timer >= 3.5:

				attack_cooldown_timer = 0.0

				if not _attack_lock:
					_attack_lock = true
					_start_spiral_wave_attack()

			# =====================================================
			# 👾 MINIONS DURANTE EL DESCANSO
			# =====================================================
			sub_pattern_timer += delta

			if sub_pattern_timer >= 8.0:

				sub_pattern_timer = 0.0

				_spawn_flying_minion()

				await get_tree().create_timer(0.6).timeout

				_spawn_flying_minion()

		State.TRANSITION_F3:
			velocity = Vector2.ZERO
			if phase_timer >= 1.0:
				current_state = State.MADNESS
				phase_timer = 0.0
				attack_cooldown_timer = 0.0
				sub_pattern_timer = 0.0

		State.MADNESS:

			var dist_player := global_position.distance_to(
				player.global_position
			)

			# =====================================
			# PERSECUCIÓN DESPUÉS DEL DASH
			# =====================================
			if madness_chasing:

				var chase_dir := (
					player.global_position - global_position
				).normalized()

				speed = _base_speed * 2.3

				_apply_oscillating_movement(
					delta,
					chase_dir,
					dist_player,
					70.0,
					20.0
				)

				# daño cuerpo a cuerpo
				if dist_player <= 65.0:

					if punch_timer.time_left <= 0.0:

						_do_melee_punch(chase_dir)

				# jugador escapó
				if dist_player > 350.0:

					madness_chasing = false

					attack_cooldown_timer = 999.0

			# =====================================
			# VOLVER AL MARCADOR DERECHO
			# =====================================
			else:

				if right_attack:

					var dist_marker := global_position.distance_to(
						right_attack.global_position
					)

					_move_to_marker_safely(
						right_attack.global_position,
						delta,
						1.8
					)

					# llegó al marcador
					if dist_marker < 25.0:

						attack_cooldown_timer += delta

						if attack_cooldown_timer >= 0.4:

							attack_cooldown_timer = 0.0

							if not _attack_lock:

								await _perform_screen_dash()

								madness_chasing = true

			# =====================================
			# INVOCACIONES
			# =====================================
			sub_pattern_timer += delta

			if sub_pattern_timer >= 4.0:

				_spawn_earth_minion()

			if sub_pattern_timer >= 8.0:

				sub_pattern_timer = 0.0

				_spawn_flying_minion()

				if randi() % 2 == 0:

					_spawn_flying_minion()


		State.FINAL_DESPERATION:
			_apply_oscillating_movement(delta, dir, dist, 200.0, 80.0)
			
			attack_cooldown_timer += delta
			if attack_cooldown_timer >= 0.6: 
				attack_cooldown_timer = 0.0
				_shoot_spiral_wave()
				
			sub_pattern_timer += delta
			if sub_pattern_timer >= 2.5: 
				sub_pattern_timer = 0.0
				_spawn_danger_zone()

# ----------------- ATAQUES Y MECÁNICAS -----------------

## Función estabilizadora para anclar los viajes directos a los marcadores
func _move_to_marker_safely(
	target_pos: Vector2,
	delta: float,
	speed_mult := 1.0
) -> void:

	var distance := global_position.distance_to(target_pos)

	# Si ya llegó, detenerse
	if distance < 10.0:
		velocity = Vector2.ZERO
		return

	var move_dir := (
		target_pos - global_position
	).normalized()

	# Reducir velocidad al acercarse para evitar rebotes
	var final_speed := speed * speed_mult

	if distance < 80.0:
		final_speed *= distance / 80.0

	velocity = move_dir * final_speed

func _apply_oscillating_movement(delta: float, dir: Vector2, dist: float, max_r: float, min_r: float) -> void:
	walk_phase += delta
	var target_vel := Vector2.ZERO
	
	if _attack_lock:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)
		return

	var phase := walk_phase * TAU
	var offset = Vector2(
		sin(phase * walk_freq + walk_seed) * side_amp,
		sin(phase * up_freq + walk_seed * 0.73) * up_amp
	)

	if dist > max_r:
		target_vel = (dir * speed) + offset
	elif dist < min_r:
		target_vel = (-dir * (speed * 0.8)) + offset
	else:
		target_vel = offset

	velocity = velocity.move_toward(target_vel, accel * delta)

func _do_melee_punch(dir: Vector2) -> void:
	if target_in_range and target_in_range.has_signal("damage"):
		target_in_range.emit_signal("damage", 20.0)
		if sfx_hit: sfx_hit.play()
		
	_attack_lock = true
	var start := global_position
	var end := start + dir * 38.0
	if _tween and _tween.is_running(): _tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", end, 0.12)
	_tween.tween_property(self, "global_position", start, 0.12)
	punch_timer.start(0.6)
	await punch_timer.timeout
	_attack_lock = false

func _shoot_burst_attack(dir: Vector2) -> void:

	if bullet_scene == null:
		return

	if _attack_lock:
		return

	_attack_lock = true

	# 5 balas por ráfaga
	for i in range(5):

		var bullet = bullet_scene.instantiate()

		get_parent().add_child(bullet)

		bullet.global_position = global_position

		var mod_dir = dir.rotated(
			randf_range(-0.20, 0.20)
		)

		if bullet.has_method("setup"):
			bullet.setup(mod_dir, 400.0)

		await get_tree().create_timer(0.08).timeout

	await get_tree().create_timer(0.5).timeout

	_attack_lock = false


func _shoot_spiral_wave() -> void:
	if bullet_scene == null: return
	var num_bullets := 8
	spiral_angle += 12.0 
	for i in range(num_bullets):
		var angle = deg_to_rad(spiral_angle + (i * (360.0 / num_bullets)))
		var b_dir = Vector2(cos(angle), sin(angle))
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		if b.has_method("setup"):
			b.setup(b_dir, 300.0)

func _spawn_danger_zone() -> void:

	if danger_zone_scene == null:
		return

	var danger_root = get_node_or_null("../DangerZonePoints")

	if danger_root == null:
		return

	var markers := []

	for child in danger_root.get_children():

		if child is Marker2D:
			markers.append(child)

	if markers.is_empty():
		return

	# cantidad de bombas por oleada
	var bomb_count := int(min(6, markers.size()))

	var usados := []

	for i in range(bomb_count):

		var marker: Marker2D = markers.pick_random()

		while marker in usados:
			marker = markers.pick_random()

		usados.append(marker)

		var zone = danger_zone_scene.instantiate()

		get_parent().add_child(zone)

		zone.global_position = marker.global_position

		if zone.has_method("setup_zone"):
			zone.setup_zone(randf_range(0.7, 1.0))

func _perform_screen_dash() -> void:

	if player == null:
		return

	_attack_lock = true

	var hit_player := false

	var dash_dir := (
		player.global_position - global_position
	).normalized()

	var target_pos := global_position + dash_dir * 1000.0

	var tween := create_tween()

	tween.tween_property(
		self,
		"global_position",
		target_pos,
		0.18
	)

	while tween.is_running():

		if not hit_player:

			if global_position.distance_to(
				player.global_position
			) <= 90.0:

				hit_player = true

				if player.has_method("recibir_daño"):
					player.recibir_daño(40)

				elif player.has_method("recibir_dano"):
					player.recibir_dano(40)

				# inmediatamente empieza persecución
				madness_chasing = true

		await get_tree().process_frame

	await tween.finished

	_attack_lock = false

func _spawn_flying_minion() -> void:
	if minion_scene == null:
		return
	var current_minions = []
	for node in get_tree().get_nodes_in_group("boss_minion"):
		if is_instance_valid(node):
			current_minions.append(node)

	# máximo absoluto
	if current_minions.size() >= 3:
		return

	var minion = minion_scene.instantiate()

	get_parent().add_child(minion)

	minion.global_position = global_position + Vector2(
		randf_range(-420, 420),
		randf_range(-220, 220)
	)

func _spawn_earth_minion() -> void:
	if minion_2 == null:
		return
	var current_minions_2 = []
	for node in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(node):
			current_minions_2.append(node)

	# máximo absoluto
	if current_minions_2.size() >= 4:
		return

	var minion = minion_2.instantiate()

	get_parent().add_child(minion)

	minion.global_position = global_position + Vector2(
		randf_range(-420, 420),
		randf_range(-220, 220)
	)


# ----------------- TRANSICIONES DE FASE -----------------
func _trigger_transition_f2() -> void:
	_f2_triggered = true
	current_state = State.TRANSITION_F2
	phase_timer = 0.0
	velocity = Vector2.ZERO
	
	var cam = get_tree().get_first_node_in_group("camara") as Camera2D
	if cam and cam.has_method("shake"): cam.call("shake", 0.5, 15) 
	
	var t = create_tween()
	t.tween_property(sprite_2d, "modulate", Color(5, 5, 5, 1), 0.1) 
	t.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.3)

func _trigger_transition_f3() -> void:
	_f3_triggered = true
	current_state = State.TRANSITION_F3
	phase_timer = 0.0
	velocity = Vector2.ZERO
	
	var t = create_tween()
	t.tween_property(sprite_2d, "modulate", Color(0, 0, 0, 1), 0.2) 
	t.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.2).set_delay(1.0)

func _enter_desperation_mode() -> void:
	_desperation_triggered = true
	current_state = State.FINAL_DESPERATION
	phase_timer = 0.0
	speed = _base_speed * 0.7 

# ----------------- DAÑO Y MUERTE -----------------
func _hp_pct() -> float:
	if vida_max <= 0: return 1.0
	return float(vida) / float(vida_max)

func recibir_daño(cantidad: int) -> void:
	if dead or en_cooldown_golpe: 
		return
		
	en_cooldown_golpe = true
	vida = max(vida - cantidad, 0)
	
	if bar_boss:
		bar_boss.value = vida

	_stack_value += cantidad
	label.text = str(int(_stack_value))
	label.visible = true
	label.position = _label_base_pos
	label.scale = Vector2.ONE

	var col := Color(1, 1, 1, 1)
	if _stack_value <= 20: col = Color(1, 1, 1, 1)
	elif _stack_value <= 40: col = Color(1, 1, 0, 1)
	else: col = Color(1, 0, 0, 1)
	label.modulate = col

	if _tween and _tween.is_running() and not _attack_lock: _tween.kill()
	var t := create_tween()
	t.tween_property(label, "position:y", _label_base_pos.y - 16.0, 0.22)
	t.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.16)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.32).set_delay(0.04)
	_stack_timer.start(0.4)

	if sfx_hit:
		sfx_hit.pitch_scale = randf_range(0.8, 1.5)
		sfx_hit.play()

	if vida <= 0:
		_die()
		return

	if sprite_2d and sprite_2d.sprite_frames.has_animation("golpeado"):
		sprite_2d.play("golpeado")

	timer_golpe.start()

func _fin_golpe() -> void:
	en_cooldown_golpe = false

func _die() -> void:
	dead = true
	label.visible = false
	velocity = Vector2.ZERO
	area.set_deferred("monitoring", false)
	
	var projectiles = get_tree().get_nodes_in_group("boss_bullet")
	for p in projectiles:
		if p.has_method("queue_free"): p.queue_free()

	var col := get_node_or_null("CollisionShape2D")
	if col: col.set_deferred("disabled", true)
	
	if sprite_2d and sprite_2d.sprite_frames and sprite_2d.sprite_frames.has_animation("explosion"):
		sprite_2d.sprite_frames.set_animation_loop("explosion", false)
		sprite_2d.frame = 0
		sprite_2d.play("explosion")
		
	else:
		explosion_timer.start(0.3)

	await get_tree().create_timer(1.2).timeout

	queue_free()

# ----------------- EVENTOS DE COLISIÓN (AREA2D) -----------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		target_in_range = body as CharacterBody2D
	if body.is_in_group("player_1_bullet"):
		recibir_daño(10)
		if body.has_method("queue_free"): body.queue_free()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == target_in_range:
		target_in_range = null

func _start_spiral_wave_attack() -> void:

	if bullet_scene == null:
		_attack_lock = false
		return

	velocity = Vector2.ZERO

	# =====================================================
	# ACTIVA MÁS RÁPIDO
	# =====================================================
	await get_tree().create_timer(0.25).timeout

	# =====================================================
	# SOLO 3 OLEADAS
	# =====================================================
	var waves := 3

	for wave in range(waves):

		# =================================================
		# SOLO 6 BALAS
		# =================================================
		# Mucho espacio libre
		var bullet_count := 6

		# rotación progresiva
		var rotation = wave * 24.0

		for i in range(bullet_count):

			var angle = deg_to_rad(
				(i * (360.0 / bullet_count))
				+ rotation
			)

			var dir = Vector2(
				cos(angle),
				sin(angle)
			)

			var bullet = bullet_scene.instantiate()
			get_parent().add_child(bullet)

			bullet.global_position = global_position

			# MÁS LENTAS
			if bullet.has_method("setup"):
				bullet.setup(dir, 150.0)

		# =================================================
		# ESPACIO ENTRE OLEADAS
		# =================================================
		await get_tree().create_timer(0.55).timeout

	# =====================================================
	# INVOCAR MINIONS DISPERSOS
	# =====================================================

	for i in range(2):

		_spawn_flying_minion()

	# pequeño descanso
	await get_tree().create_timer(0.8).timeout

	_attack_lock = false
