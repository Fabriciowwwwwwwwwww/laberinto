extends CanvasLayer

@onready var mapa: Control = $Control
@onready var lupa: TextureRect = $lupa

var abierto := false

@export var textura_lupa: Texture2D
@export var radio_lupa := 80

# -------------------------
# READY
# -------------------------
func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if lupa == null:
		push_error("❌ Nodo Lupa no encontrado")
		return
	
	lupa.z_index = 100  # 🔥 CLAVE
	
	if textura_lupa:
		lupa.texture = textura_lupa
	
	lupa.mouse_filter = Control.MOUSE_FILTER_STOP
	lupa.visible = false

# -------------------------
# INPUT
# -------------------------
func _unhandled_input(event):
	if event.is_action_pressed("mapa"):
		toggle_mapa()

# -------------------------
# TOGGLE
# -------------------------
func toggle_mapa():
	abierto = !abierto
	visible = abierto
	get_tree().paused = abierto
	
	if abierto:
		lupa.visible = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		lupa.visible = false

# -------------------------
# BOTON
# -------------------------
func _on_button_pressed() -> void:
	toggle_mapa()

# -------------------------
# SEGUIR MOUSE (FIX)
# -------------------------
func _process(delta):
	if not abierto:
		return
	

	
	# 🔥 detectar revelables
	for r in get_tree().get_nodes_in_group("revelables"):
		r.actualizar_revelado(lupa.global_position, radio_lupa)
