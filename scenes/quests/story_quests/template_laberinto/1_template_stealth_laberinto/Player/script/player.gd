extends CharacterBody2D
class_name Player_l

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_arma: AnimatedSprite2D = $arma/AnimatedSprite2D
@onready var stamina_bar: ProgressBar = $Stamina
@onready var arma_node: Node2D = $arma
@onready var arma_sonido: Node2D = $arma/arma_sonido
# -------- LLAVES --------
@onready var llaves: Node = safe_get_node("../llaves")
@onready var keys_label: Label = safe_get_node("../llaves/Keys_label")

# -------- VIDA --------
@export var vida_maxima: int = 100
var vida_actual: int = 100
@onready var vida_bar: TextureProgressBar = safe_get_node("../barra vida/ProgressBar")

# -------- BALAS --------
@export var escena_bala: PackedScene
@onready var balas_vista: Node = safe_get_node("../BalasVista")

# -------- MOVIMIENTO --------
@export var WALK_SPEED: float = 300.0
@export var RUN_SPEED: float = 500.0

var current_speed: float = 300.0
var last_direction: Vector2 = Vector2.DOWN

# -------- STAMINA --------
const MAX_STAMINA: float = 100.0
const STAMINA_DRAIN_RATE: float = 20.0
const STAMINA_REGEN_RATE: float = 6.0

var current_stamina: float = MAX_STAMINA
var is_running: bool = false
var can_run: bool = true

# -------- INTERACCIONES --------
var current_chest: Chest = null
var current_door: Node = null  # O simplemente 'var current_door = null'
var keys_collected: int = 0


# =====================================================
# FUNCION SEGURA
# =====================================================
func safe_get_node(path: NodePath) -> Node:
	if has_node(path):
		return get_node(path)
	return null


# =====================================================
# READY
# =====================================================
func _ready() -> void:
	add_to_group("player")
	aplicar_skin()  # 👈 AÑADE ESTO

	# 🔥 SI VIENE DEL EXTERIOR → aparece dentro de la cabaña
	if Gamestateminijuegos.viene_de_exterior:
		var spawn = get_tree().get_first_node_in_group("spawn_interior")

		if spawn:
			global_position = spawn.global_position
			print("SPAWN INTERIOR:", global_position)

		Gamestateminijuegos.viene_de_exterior = false

	# 🔥 SI VIENE DEL INTERIOR → vuelve afuera
	elif Gamestateminijuegos.viene_de_interior:
		global_position = Gamestateminijuegos.posicion_entrada_exterior + Vector2(0, 80) # 🔥 empuja hacia abajo
		print("VOLVIENDO AFUERA:", global_position)

		Gamestateminijuegos.viene_de_interior = false

	arma_sonido.bus = "SFX"

	vida_actual = vida_maxima
	current_speed = WALK_SPEED

	configurar_inputs()
	setup_stamina_bar()

	# DEBUG LLAVES
	keys_label = get_tree().get_root().get_node("Main/Llaves/Keys_label") as Label
	
	if keys_label == null:
		print("❌ No se encontró Keys_label")
	else:
		update_keys_ui()

	# VIDA
	if vida_bar:
		vida_bar.max_value = vida_maxima
		vida_bar.value = vida_actual
		actualizar_color_vida()


# =====================================================
# INPUTS
# =====================================================
func configurar_inputs() -> void:

	if not InputMap.has_action("disparar"):
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.add_action("disparar")
		InputMap.action_add_event("disparar", mouse_event)

	if not InputMap.has_action("Interact"):
		var key_e := InputEventKey.new()
		key_e.physical_keycode = KEY_E
		InputMap.add_action("Interact")
		InputMap.action_add_event("Interact", key_e)

	if not InputMap.has_action("run"):
		var shift_event := InputEventKey.new()
		shift_event.physical_keycode = KEY_SHIFT
		InputMap.add_action("run")
		InputMap.action_add_event("run", shift_event)

	if not InputMap.has_action("recargar"):
		var key_r := InputEventKey.new()
		key_r.physical_keycode = KEY_R
		InputMap.add_action("recargar")
		InputMap.action_add_event("recargar", key_r)


# =====================================================
# STAMINA
# =====================================================
func setup_stamina_bar() -> void:
	stamina_bar.max_value = MAX_STAMINA
	stamina_bar.value = current_stamina
	stamina_bar.show_percentage = false
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	stamina_bar.add_theme_stylebox_override("background", bg_style)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	stamina_bar.add_theme_stylebox_override("fill", fill_style)



# =====================================================
# MOVIMIENTO

func _physics_process(delta: float) -> void:

	# =========================
	# INPUT DEBUG
	# =========================
	var run_pressed = Input.is_action_pressed("run")

	# =========================
	# RUN / STAMINA
	# =========================
	if run_pressed and can_run and current_stamina > 0:
		current_speed = RUN_SPEED
		is_running = true
	else:
		current_speed = WALK_SPEED
		is_running = false

	handle_stamina(delta)

	# =========================
	# ACCIONES
	# =========================
	actualizar_pistola()

	if Input.is_action_just_pressed("disparar"):
		disparar()

	if Input.is_action_just_pressed("recargar"):
		recargar()
	

	# =========================
	# MOVIMIENTO
	# =========================
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

	velocity = input_vector * current_speed

	handle_animations(input_vector)
	move_and_slide()

	handle_interaction()
# =====================================================
# PISTOLA
# =====================================================
func update_stamina_bar() -> void:
	stamina_bar.value = current_stamina

	var fill_style = stamina_bar.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		var style = fill_style as StyleBoxFlat
		if current_stamina > 60:
			style.bg_color = Color(0.2, 0.8, 0.3, 1.0)
		elif current_stamina > 30:
			style.bg_color = Color(0.8, 0.8, 0.2, 1.0)
		else:
			style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
func actualizar_pistola() -> void:

	var direccion: Vector2 = (get_global_mouse_position() - global_position).normalized()
	var angulo: float = direccion.angle()

	arma_node.rotation = angulo
	arma_node.position = Vector2.RIGHT.rotated(angulo) * 23.0

	animated_arma.flip_v = rad_to_deg(angulo) > 90 or rad_to_deg(angulo) < -90


func disparar() -> void:

	if balas_vista and balas_vista.procesar_disparo():

		arma_sonido.play()
		animated_arma.play("disparo_revolver")

		var bala = escena_bala.instantiate()
		bala.global_position = $arma/Marker2D.global_position
		bala.direction = Vector2.RIGHT.rotated($arma.global_rotation)

		get_tree().current_scene.add_child(bala)



func recargar() -> void:
	animated_arma.play("arma_recarga")


# =====================================================
# ANIMACIONES
# =====================================================
func handle_animations(movement_vector: Vector2) -> void:

	if movement_vector != Vector2.ZERO:
		last_direction = movement_vector

	var is_moving: bool = movement_vector != Vector2.ZERO
	var anim_name: String = ""

	if is_moving:
		if abs(movement_vector.x) >= abs(movement_vector.y):
			anim_name = "MoveDerecha"
			animated_sprite_2d.flip_h = movement_vector.x > 0
		else:
			anim_name = "MoveAbajo" if movement_vector.y > 0 else "MoveArriba"
	else:
		if abs(last_direction.x) >= abs(last_direction.y):
			anim_name = "idle"
			animated_sprite_2d.flip_h = last_direction.x > 0
		else:
			anim_name = "idle" if last_direction.y > 0 else "idle"

	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func set_current_chest(chest: Chest)-> void:
	if current_chest and current_chest != chest: 
		current_chest.player_exit() 
	current_chest = chest 
func clear_current_chest()-> void: 
	current_chest = null 
	
func set_current_door(door)-> void:
	if current_door and current_door != door: 
		current_door.player_exit() 
	current_door = door 
	
func clear_current_door()-> void:
	current_door = null
# =====================================================
# INTERACCIONES
# =====================================================
func handle_interaction() -> void:

	if current_chest and Input.is_action_pressed("Interact"):
		current_chest.start_interaction()
	elif current_chest and not Input.is_action_pressed("Interact"):
		current_chest.stop_interaction()

	if current_door and Input.is_action_just_pressed("Interact"):
		current_door.interact()


# =====================================================
# LLAVES
# =====================================================
func collect_key() -> void:

	keys_collected += 1
	update_keys_ui()

	if current_door:
		current_door.check_door_status()


func update_keys_ui() -> void:

	if keys_label == null:
		return

	if keys_collected >= 10:
		keys_label.text = "✅ ¡Ve a la puerta de salida!"
	else:
		keys_label.text = "Llaves: " + str(keys_collected) + "/10"


# =====================================================
# VIDA
# =====================================================
func recibir_daño(cantidad: int) -> void:
	vida_actual -= cantidad
	vida_actual = max(vida_actual, 0)

	if vida_bar:
		vida_bar.value = vida_actual
		actualizar_color_vida()

	if vida_actual <= 0:
		morir()


func actualizar_color_vida() -> void:
	if not vida_bar:
		return

	var barra := vida_bar.get_theme_stylebox("fill")

	if barra is StyleBoxFlat:
		var color := Color(0.2, 0.8, 0.3)

		if vida_actual <= 30:
			color = Color(0.8, 0.2, 0.2)
		elif vida_actual <= 60:
			color = Color(0.8, 0.8, 0.2)

		barra.bg_color = color


signal jugador_derrotado

func morir() -> void:
	emit_signal("jugador_derrotado")
	
	GameStateLaberinto.reset()
	
	var nextscene = preload("res://scenes/globals/ventana muerte/muerte.tscn")
	
	SceneSwitcher2.change_to_packed_with_transition(
		nextscene,
		^"",
		Transition.Effect.FADE,
		Transition.Effect.FADE
	)

func get_cofres_abiertos() -> Array:
	var ids: Array = []

	for cofre in get_tree().get_nodes_in_group("cofre"):
		if cofre.is_opened:
			ids.append(cofre.name)

	return ids


func set_cofres_abiertos(ids: Array) -> void:
	for cofre in get_tree().get_nodes_in_group("cofre"):
		if cofre.name in ids:
			cofre.abrir_sin_interaccion()
			
func sumar_vida(cantidad: int = 25) -> void:
	vida_actual += cantidad
	vida_actual = clamp(vida_actual, 0, vida_maxima)

	if vida_bar:
		vida_bar.value = vida_actual
		actualizar_color_vida()

	print("Vida actual: ", vida_actual)
func handle_stamina(delta: float) -> void:
	if is_running:
		current_stamina -= STAMINA_DRAIN_RATE * delta
		if current_stamina <= 0:
			current_stamina = 0
			can_run = false
	else:
		current_stamina += STAMINA_REGEN_RATE * delta

		if current_stamina >= MAX_STAMINA:
			current_stamina = MAX_STAMINA

		if current_stamina > 20:
			can_run = true

	update_stamina_bar()
	# Guardar el estado del jugador
func aplicar_skin():
	if GameStateSkin.skin_actual:
		animated_sprite_2d.sprite_frames = GameStateSkin.skin_actual
		animated_sprite_2d.play("idle")
