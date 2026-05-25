extends CharacterBody2D

signal damage(value: float)
signal died

# ----------------- NUEVA ESTRUCTURA DE FASES -----------------
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

# --- Puntos de Ataque (Cargados desde la escena) ---
@onready var left_attack = $"../Final_Boss/AttackPoints/LeftAttack"
@onready var center_attack = $"../Final_Boss/AttackPoints/CenterAttack"
@onready var right_attack = $"../Final_Boss/AttackPoints/RightAttack"

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
var up_freq := 1.8          # 👈 ¡Añade esta línea exacta!
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

	# Conexiones seguras de colisiones
	area.monitoring = true
	if not area.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	if not area.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		area.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))

	# Inicializar temporizador de golpes físicos
	punch_timer.one_shot = true

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
	# Comprobaciones de Vida (Cambios de fase prioritarios)
	var hp_pct = _hp_pct()
	if hp_pct <= 0.10 and not _desperation_triggered and current_state == State.MADNESS:
		_enter_desperation_mode()
	elif hp_pct <= 0.33 and not _f3_triggered and current_state == State.BULLET_HELL:
		_trigger_transition_f3()
		return
	elif hp_pct <= 0.66 and not _f2_triggered and (current_state == State.CHASE_1 or current_state == State.RANGED_ATTACK or current_state == State.CHASE_2):
		_trigger_transition_f2()
		return

	match current_state:
		State.READY_GO:
			velocity = Vector2.ZERO
			if phase_timer >= 1.5: # Sincronizado con tu animación de 1.5s
				if player and player.has_method("set_physics_process"):
					player.set_physics_process(true)
				current_state = State.CHASE_1
				phase_timer = 0.0

		State.CHASE_1:
			speed = _base_speed
			_apply_oscillating_movement(delta, dir, dist, 140.0, 70.0)
			if dist <= 80.0 and punch_timer.time_left <= 0.0:
				_do_melee_punch(dir)
			
			# Cambio automático a los 6 segundos
			if phase_timer >= 6.0:
				current_state = State.RANGED_ATTACK
				phase_timer = 0.0
				sub_pattern_timer = 0.0
				_attack_lock = false

		State.RANGED_ATTACK:
			# Deslizarse / Moverse hacia LeftAttack
			if left_attack:
				target_position = left_attack.global_position
				velocity = velocity.move_toward((target_position - global_position).normalized() * (_base_speed * 1.5), accel * delta)
			else:
				velocity = Vector2.ZERO

			# Ráfagas de disparos cada 1.5 segundos
			attack_cooldown_timer += delta
			if attack_cooldown_timer >= 1.5:
				attack_cooldown_timer = 0.0
				_shoot_burst_attack(dir)

			# Círculos / Zonas Peligrosas en el mapa cada 1.2s
			sub_pattern_timer += delta
			if sub_pattern_timer >= 1.2:
				sub_pattern_timer = 0.0
				_spawn_danger_zone()

			if phase_timer >= 7.0: # Duración del patrón (7s -> 13s)
				current_state = State.CHASE_2
				phase_timer = 0.0

		State.CHASE_2:
			# Más rápido y agresivo
			speed = _base_speed * 1.3
			_apply_oscillating_movement(delta, dir, dist, 160.0, 50.0)
			if dist <= 80.0 and punch_timer.time_left <= 0.0:
				_do_melee_punch(dir)

			# Bucle si no ha bajado del 66% de vida
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
			# Ir al centro
			if center_attack:
				var to_center = center_attack.global_position - global_position
				if to_center.length() > 10.0:
					velocity = velocity.move_toward(to_center.normalized() * (_base_speed * 0.8), accel * delta)
				else:
					velocity = Vector2.ZERO
			
			# Espiral de proyectiles cada 0.15s
			attack_cooldown_timer += delta
			var current_spiral_speed = 0.15 if phase_timer < 8.0 else 0.08 # Acelera a los 28 segundos globales del diseño
			if attack_cooldown_timer >= current_spiral_speed:
				attack_cooldown_timer = 0.0
				_shoot_spiral_wave()

			# Cambiar ligeramente de posición cada 4 segundos
			sub_pattern_timer += delta
			if sub_pattern_timer >= 4.0:
				sub_pattern_timer = 0.0
				# Pequeña variación aleatoria alrededor del centro
				if center_attack:
					global_position = center_attack.global_position + Vector2(randf_range(-60, 60), randf_range(-30, 30))

		State.TRANSITION_F3:
			velocity = Vector2.ZERO
			if phase_timer >= 2.0:
				current_state = State.MADNESS
				phase_timer = 0.0
				attack_cooldown_timer = 0.0
				sub_pattern_timer = 0.0
				# Teletransportar o posicionar a la izquierda
				if left_attack:
					global_position = left_attack.global_position

		State.MADNESS:
			# Lógica de Embestidas / Dash horizontal de Cuphead
			velocity = Vector2.ZERO
			attack_cooldown_timer += delta
			
			# Ciclo de Embiste: 1s de aviso (línea roja), luego cruza la pantalla
			if attack_cooldown_timer >= 3.0: 
				attack_cooldown_timer = 0.0
				_perform_screen_dash()

			# Esbirros / Sombras voladoras cada 8 segundos
			sub_pattern_timer += delta
			if sub_pattern_timer >= 8.0:
				sub_pattern_timer = 0.0
				_spawn_flying_minion()

		State.FINAL_DESPERATION:
			# Último 10% - Mezcla lenta de todo
			_apply_oscillating_movement(delta, dir, dist, 200.0, 80.0)
			
			attack_cooldown_timer += delta
			if attack_cooldown_timer >= 0.6: # Espirales más espaciadas
				attack_cooldown_timer = 0.0
				_shoot_spiral_wave()
				
			sub_pattern_timer += delta
			if sub_pattern_timer >= 2.5: # Zonas peligrosas pausadas
				sub_pattern_timer = 0.0
				_spawn_danger_zone()

# ----------------- ATAQUES Y MECÁNICAS -----------------
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
	if bullet_scene == null: return
	for i in range(3): # Ráfaga corta de 3 proyectiles
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		# Desviación pequeña por bala para imperfección natural
		var mod_dir = dir.rotated(randf_range(-0.1, 0.1))
		if b.has_method("setup"):
			b.setup(mod_dir, 320.0) # Velocidades medianamente lentas
		await get_tree().create_timer(0.15).timeout

func _shoot_spiral_wave() -> void:
	if bullet_scene == null: return
	var num_bullets := 8
	spiral_angle += 12.0 # Rotación progresiva del patrón
	for i in range(num_bullets):
		var angle = deg_to_rad(spiral_angle + (i * (360.0 / num_bullets)))
		var b_dir = Vector2(cos(angle), sin(angle))
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		if b.has_method("setup"):
			b.setup(b_dir, 260.0)

func _spawn_danger_zone() -> void:
	if danger_zone_scene == null: return
	var zone = danger_zone_scene.instantiate()
	get_parent().add_child(zone)
	
	# Puntos aleatorios alrededor de la arena o del jugador
	var random_offset = Vector2(randf_range(-300, 300), randf_range(-150, 150))
	var spawn_pos = player.global_position + random_offset if player else global_position + random_offset
	zone.global_position = spawn_pos
	
	if zone.has_method("setup_zone"):
		zone.setup_zone(0.8) # 0.8s para la explosión según diseño

func _perform_screen_dash() -> void:
	_attack_lock = true
	# 1. Mostrar advertencia visual / línea de carga aquí (puedes usar un Tween de color o un Sprite)
	await get_tree().create_timer(1.0).timeout # 1 Segundo de advertencia
	
	# 2. Cruzar la pantalla (BOOM)
	var dash_dir = Vector2.RIGHT if global_position.x < 500 else Vector2.LEFT
	var original_gravity_state = is_on_floor() 
	
	var dash_tween = create_tween()
	var target_x = global_position.x + (dash_dir.x * 1200)
	dash_tween.tween_property(self, "global_position:x", target_x, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# Generar daño durante el trayecto si colisiona
	await dash_tween.finished
	_attack_lock = false

func _spawn_flying_minion() -> void:
	if minion_scene == null: return
	var minion = minion_scene.instantiate()
	get_parent().add_child(minion)
	minion.global_position = global_position + Vector2(randf_range(-100, 100), -200) # Aparece desde arriba/sombras

# ----------------- TRANSICIONES DE FASE (HP) -----------------
func _trigger_transition_f2() -> void:
	_f2_triggered = true
	current_state = State.TRANSITION_F2
	phase_timer = 0.0
	velocity = Vector2.ZERO
	
	# Efectos cinemáticos
	var cam = get_tree().get_first_node_in_group("camara") as Camera2D
	if cam and cam.has_method("shake"): cam.call("shake", 0.5, 15) # Shake de cámara opcional
	
	# Flash blanco usando modulaciones en un Tween rápido
	var t = create_tween()
	t.tween_property(sprite_2d, "modulate", Color(5, 5, 5, 1), 0.1) # Brillo/Flash
	t.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.3)

func _trigger_transition_f3() -> void:
	_f3_triggered = true
	current_state = State.TRANSITION_F3
	phase_timer = 0.0
	velocity = Vector2.ZERO
	
	# Oscuridad breve / Feedback visual
	var t = create_tween()
	t.tween_property(sprite_2d, "modulate", Color(0, 0, 0, 1), 0.2) # Desaparece en sombra
	t.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.2).set_delay(1.0)

func _enter_desperation_mode() -> void:
	_desperation_triggered = true
	current_state = State.FINAL_DESPERATION
	phase_timer = 0.0
	speed = _base_speed * 0.7 # Caos total pero más lento para no ser injusto

# ----------------- DAÑO Y MUERTE -----------------
func _hp_pct() -> float:
	if bar_boss == null: return 1.0
	if bar_boss.max_value <= bar_boss.min_value: return 1.0
	return (bar_boss.value - bar_boss.min_value) / (bar_boss.max_value - bar_boss.min_value)

func _on_damage(amount: float) -> void:
	if dead: return
	if bar_boss:
		bar_boss.value = clamp(bar_boss.value - amount, bar_boss.min_value, bar_boss.max_value)

	# Sistema de Stack de números de daño flotantes
	_stack_value += amount
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

	# Sonido alternado al ser impactado
	if sfx_hit:
		sfx_hit.pitch_scale = randf_range(0.8, 1.5)
		sfx_hit.play()

	if bar_boss and bar_boss.value <= bar_boss.min_value:
		_die()

func _die() -> void:
	dead = true
	label.visible = false
	velocity = Vector2.ZERO
	area.set_deferred("monitoring", false)
	
	# Quitar proyectiles activos del mapa para dejar limpio el escenario
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

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		target_in_range = body as CharacterBody2D
	if body.is_in_group("player_1_bullet"):
		emit_signal("damage", 10.0)
		if body.has_method("queue_free"): body.queue_free()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == target_in_range:
		target_in_range = null
