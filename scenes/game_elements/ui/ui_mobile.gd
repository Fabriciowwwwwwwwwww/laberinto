extends Control

@onready var btn_disparar = $Disparar
@onready var btn_interactuar = $Interactuar
@onready var btn_run = $Correr

func _ready():
	visible = InputManager.es_movil

	btn_disparar.pressed.connect(_on_disparar)
	btn_interactuar.pressed.connect(_on_interactuar)
	btn_run.pressed.connect(_on_run)

func _on_disparar():
	Input.action_press("disparar")

func _on_interactuar():
	Input.action_press("Interact")

func _on_run():
	Input.action_press("run")
