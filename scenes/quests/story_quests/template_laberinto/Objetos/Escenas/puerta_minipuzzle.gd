extends StaticBody2D

@export var next_scene_path: PackedScene

@onready var interaction_area: Area2D = $InteractionArea
@onready var interact_label: Label = $ui_container/InteractLabel
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ui_container: Control = $ui_container

var player_in_range: bool = false
var is_unlocked: bool = false
var current_player: Player_l = null

# 🔥 Cantidad de piezas necesarias (ajustado a 22 para este minijuego)
@export var piezas_necesarias := 2

# ---------------------------------------------------
func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	ui_container.visible = false
	animated_sprite_2d.play("Cerrado")

# ---------------------------------------------------
func _on_body_entered(body) -> void:
	if body is Player_l:
		player_in_range = true
		current_player = body
		body.set_current_door(self)
		check_door_status()

# ---------------------------------------------------
func _on_body_exited(body) -> void:
	if body is Player_l:
		player_exit()

func player_exit() -> void:
	player_in_range = false

	if current_player:
		current_player.clear_current_door()

	current_player = null
	hide_ui()

# ---------------------------------------------------
# ---------------------------------------------------
func check_door_status() -> void:
	if not current_player: return

	# 1. Buscamos el nodo de reglas que tiene las piezas
	var reglas = current_player.get_node_or_null("MINIJUEGOREGLAS")
	var piezas_actuales = 0
	
	if reglas:
		# Leemos el array de piezas que vas llenando
		piezas_actuales = reglas.piezas_recolectadas.size()
	
	# 2. Lógica de apertura
	if piezas_actuales >= piezas_necesarias:
		if not is_unlocked:
			unlock_door()
		else:
			show_unlocked_ui()
	else:
		# 3. Aquí es donde ocurre la magia del "22, 21, 20..."
		show_locked_ui(piezas_actuales)

func show_locked_ui(piezas_actuales: int) -> void:
	ui_container.visible = true
	# Calculamos cuánto falta exactamente
	var faltan = piezas_necesarias - piezas_actuales
	interact_label.text = "Faltan " + str(faltan) + " piezas"
# ---------------------------------------------------
func unlock_door() -> void:
	is_unlocked = true
	if animated_sprite_2d.sprite_frames.has_animation("Abierto"):
		animated_sprite_2d.play("Abierto")
	show_unlocked_ui()
	print("🚪 Puerta desbloqueada!")

# ---------------------------------------------------


# ---------------------------------------------------
func show_unlocked_ui() -> void:
	ui_container.visible = true
	interact_label.text = "Presiona E para salir"

# ---------------------------------------------------
func hide_ui() -> void:
	ui_container.visible = false

# ---------------------------------------------------
func interact() -> void:
	if is_unlocked and player_in_range:
		change_scene()

# ---------------------------------------------------
func change_scene() -> void:
	if next_scene_path:
		print("🚪 Entrando a:", next_scene_path.resource_path)
		SceneSwitcher2.change_to_packed_with_transition(
			next_scene_path,
			"",
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
