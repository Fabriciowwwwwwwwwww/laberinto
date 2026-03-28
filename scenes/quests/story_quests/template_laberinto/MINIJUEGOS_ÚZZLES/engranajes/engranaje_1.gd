extends Area2D

@export var gear_id: int = 0
@export var rotation_state: int = 0
@onready var sonido_engranaje: AudioStreamPlayer2D =$sonido_engranaje
@onready var sonido_seleccion: AudioStreamPlayer2D =$sonido_seleccion

@export var spin_speed: float = 180

var spin_direction: int = 1
var is_spinning: bool = false

# 🔒 referencia al puzzle
var puzzle

# 🔥 hover
var is_hovered: bool = false
var base_scale: Vector2
var target_scale: Vector2

@onready var sprite: Sprite2D = $Engranaje1

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	puzzle = get_tree().get_first_node_in_group("puzzle")

	base_scale = scale
	target_scale = base_scale

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# -------------------------
# PROCESO
# -------------------------
func _process(delta: float) -> void:
	# ROTACIÓN
	if is_spinning and (not puzzle or puzzle.puzzle_activo):
		rotation_degrees += spin_speed * spin_direction * delta

	# 🔥 SUAVIZAR ESCALA
	scale = scale.lerp(target_scale, 8 * delta)

# -------------------------
# INPUT
# -------------------------
func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:

		if puzzle and not puzzle.puzzle_activo:
			return

		get_tree().call_group("puzzle", "registrar_interaccion")

		is_spinning = true
		toggle_direction()

# -------------------------
# HOVER
# -------------------------
func _on_mouse_entered() -> void:
	if is_spinning:
		return
	sonido_seleccion.play()
	is_hovered = true
	target_scale = base_scale * 1.1

	if sprite:
		sprite.modulate = Color(1.2, 1.2, 1.2) # brillo blanco

func _on_mouse_exited() -> void:
	is_hovered = false
	target_scale = base_scale

	if sprite:
		sprite.modulate = Color(1, 1, 1)

# -------------------------
# CAMBIO
# -------------------------
func toggle_direction() -> void:
	sonido_engranaje.play()
	rotation_state = (rotation_state + 1) % 2
	spin_direction = 1 if rotation_state == 0 else -1

# -------------------------
# DETENER
# -------------------------
func forzar_detener() -> void:
	is_spinning = false

	# 🔥 restaurar visual
	target_scale = base_scale
	if sprite:
		sprite.modulate = Color(1, 1, 1)

# -------------------------
# RESET
# -------------------------
func reset_total() -> void:
	is_spinning = false
	rotation_degrees = 0
	rotation_state = 0
	spin_direction = 1

	target_scale = base_scale

	if sprite:
		sprite.modulate = Color(1, 1, 1)
