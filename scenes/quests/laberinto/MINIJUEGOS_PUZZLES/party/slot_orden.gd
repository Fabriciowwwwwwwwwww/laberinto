extends Control

@export var id_correcto := 0

# 🔥 ESTADOS VISUALES
enum Estado {
	GRIS,
	VERDE,
	ROJO
}

var estado_actual: Estado = Estado.GRIS

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
func evaluar(objetos, distancia_max):
	var item = obtener_item_cercano(objetos, distancia_max)

	if item == null:
		estado_actual = Estado.GRIS
		return false

	if item.id_correcto == id_correcto:
		estado_actual = Estado.VERDE
		return true
	else:
		estado_actual = Estado.ROJO
		return false

# -------------------------
func reset_visual():
	estado_actual = Estado.GRIS

# -------------------------
func _draw():
	var color := Color(0.5, 0.5, 0.5, 0.5) # gris por defecto

	match estado_actual:
		Estado.GRIS:
			color = Color(0.5, 0.5, 0.5, 0.5)
		Estado.VERDE:
			color = Color(0, 1, 0, 0.7)
		Estado.ROJO:
			color = Color(1, 0, 0, 0.7)

	draw_circle(size / 2, 35, color)

# -------------------------
func _process(_delta):
	queue_redraw()
