extends CanvasLayer

@onready var mapa: Control = $Control

var abierto := false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # 🔥 IMPORTANTE

func _unhandled_input(event):
	if event.is_action_pressed("mapa"): # tecla G
		toggle_mapa()

func toggle_mapa():
	abierto = !abierto
	visible = abierto
	get_tree().paused = abierto
