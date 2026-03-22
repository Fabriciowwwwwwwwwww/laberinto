extends StaticBody2D
class_name Chest

@export var interaction_time: float = 3.0
@export var is_opened: bool = false

@onready var audio_open: AudioStreamPlayer2D = $AudioOpen
@onready var interaction_area: Area2D = $InteractionArea
@onready var progress_bar: ProgressBar = $ui_container/ProgressBar
@onready var interact_label: Label = $ui_container/InteractLabel
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ui_container: Control = $ui_container

var player_in_range: bool = false
var is_interacting: bool = false
var interaction_progress: float = 0.0
var current_player: Player_l = null

signal chest_opened

# Tipar funciones con -> void y parámetros
func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	ui_container.visible = false
	progress_bar.min_value = 0
	progress_bar.max_value = interaction_time
	progress_bar.value = 0
	
	if not is_opened:
		animated_sprite_2d.play("Cerrado")
	else:
		animated_sprite_2d.play("Abierto")

func _process(delta: float) -> void:
	if is_interacting and player_in_range and not is_opened:
		interaction_progress += delta
		progress_bar.value = interaction_progress
		
		if interaction_progress >= interaction_time:
			open_chest()

func _on_body_entered(body: Node) -> void:
	if body is Player_l and not is_opened:
		player_in_range = true
		current_player = body
		body.set_current_chest(self)
		show_ui()

func _on_body_exited(body: Node) -> void:
	if body is Player_l:
		player_exit()

func player_exit() -> void:
	player_in_range = false
	if current_player:
		current_player.clear_current_chest()
		current_player = null
	stop_interaction()
	hide_ui()

func start_interaction() -> void:
	if not is_opened and player_in_range:
		is_interacting = true
		interact_label.text = "Abriendo cofre..."
		if not audio_open.playing:
			audio_open.play()

func stop_interaction() -> void:
	is_interacting = false
	interaction_progress = 0.0
	progress_bar.value = 0
	if audio_open.playing:
		audio_open.stop()
	if not is_opened:
		interact_label.text = "Mantén E para abrir"

func open_chest() -> void:
	is_opened = true
	is_interacting = false
	interaction_progress = 0.0
	
	print("¡Cofre abierto!")
	if current_player:
		current_player.collect_key()
	
	chest_opened.emit()
	animated_sprite_2d.play("Abierto")
	hide_ui()

func show_ui() -> void:
	ui_container.visible = true
	interact_label.text = "Mantén E para abrir"

func hide_ui() -> void:
	ui_container.visible = false

func abrir_sin_interaccion() -> void:
	is_opened = true
	animated_sprite_2d.play("Abierto")
	ui_container.visible = false
	
