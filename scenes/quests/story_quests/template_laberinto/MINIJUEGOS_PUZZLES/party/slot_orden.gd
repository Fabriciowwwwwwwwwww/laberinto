extends Control

@export var id_correcto := 0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("slot")

# -------------------------
func obtener_item_cercano(objetos, distancia_max):
	var mejor = null
	var mejor_dist = distancia_max

	for item in objetos:
		var centro_item = item.global_position + item.size / 2
		var centro_slot = global_position + size / 2

		var dist = centro_item.distance_to(centro_slot)

		if dist < mejor_dist:
			mejor_dist = dist
			mejor = item

	return mejor

# -------------------------
func es_correcto(objetos, distancia_max):
	var item = obtener_item_cercano(objetos, distancia_max)

	if item == null:
		return false

	return item.id_correcto == id_correcto

# -------------------------
func _draw():
	draw_circle(size / 2, 25, Color(1, 0, 0, 0.4))

func _process(_delta):
	queue_redraw()
