extends CanvasLayer
class_name VistaPoderes

# =====================================================
# NODOS
# =====================================================

@onready var panel: Panel = $Panel

@onready var boton_veneno: TextureButton  = $veneno
@onready var boton_bomba: TextureButton  = $bomba

@onready var cd_veneno: TextureProgressBar = $Panel/cd_veneno
@onready var cd_bomba: TextureProgressBar = $Panel/cd_bomba

@onready var player = get_tree().get_first_node_in_group("player")

@onready var veneno_node = player.get_node("VenenoSpawner")
@onready var bomba_node = player.get_node("MineSpawner")


# =====================================================
# READY
# =====================================================
func _ready():

	print("VistaPoderes lista")

	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	cd_veneno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd_bomba.mouse_filter = Control.MOUSE_FILTER_IGNORE

	boton_veneno.mouse_filter = Control.MOUSE_FILTER_STOP
	boton_bomba.mouse_filter = Control.MOUSE_FILTER_STOP

	# =====================================
	# FORZAR ENCIMA DE TODO
	# =====================================
	panel.z_index = -1

	boton_veneno.z_index = 10
	boton_bomba.z_index = 10

	boton_veneno.top_level = true
	boton_bomba.top_level = true

	cd_veneno.max_value = veneno_node.cooldown
	cd_bomba.max_value = bomba_node.use_cooldown


# =====================================================
# PROCESS
# =====================================================
func _process(delta):

	# =====================================================
	# VENENO
	# =====================================================
	cd_veneno.value = (
		veneno_node.cooldown
		- veneno_node.cooldown_timer
	)

	if veneno_node.cooldown_timer > 0:

		boton_veneno.disabled = true
		boton_veneno.modulate = Color(0.4, 0.4, 0.4)

	else:

		boton_veneno.disabled = false
		boton_veneno.modulate = Color.WHITE

	# =====================================================
	# BOMBA
	# =====================================================
	cd_bomba.value = (
		bomba_node.use_cooldown
		- bomba_node.cooldown_timer
	)

	if bomba_node.cooldown_timer > 0:

		boton_bomba.disabled = true
		boton_bomba.modulate = Color(0.4, 0.4, 0.4)

	else:

		boton_bomba.disabled = false
		boton_bomba.modulate = Color.WHITE


# =====================================================
# BOTON VENENO
# =====================================================
func _on_veneno_pressed() -> void:

	print("BOTON VENENO")

	Input.action_press("area_veneno")
	Input.action_release("area_veneno")


# =====================================================
# BOTON BOMBA
# =====================================================
func _on_bomba_pressed() -> void:

	print("BOTON BOMBA")

	Input.action_press("place_mine")
	Input.action_release("place_mine")
