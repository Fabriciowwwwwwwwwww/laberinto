extends Node2D

@export var configuracion_colores := {
	0: [Color.BLUE, Color.CYAN],
	1: [Color.RED],
	2: [Color.GREEN],
	3: [Color.YELLOW],
	4: [Color.PURPLE],
	5: [Color.ORANGE]
}

@export var variacion := 0.25

var solucion_generada := {}

func generar_colores()-> void:

	solucion_generada.clear()

	var zonas = find_children("*", "Polygon2D", true, false)

	# Generar solución
	for id in configuracion_colores.keys():

		var base = configuracion_colores[id].pick_random()
		var final = variar_color(base)

		solucion_generada[id] = final

	# Aplicar colores a las zonas
	for zona in zonas:

		# Eliminar cualquier textura que pueda teñir el color
		zona.texture = null

		# Restaurar modulación normal
		zona.modulate = Color.WHITE
		zona.self_modulate = Color.WHITE

		if not ("id_color" in zona):
			continue

		var id = zona.id_color

		if solucion_generada.has(id):

			if zona.has_method("aplicar_color"):
				zona.aplicar_color(solucion_generada[id])
			else:
				zona.color = solucion_generada[id]
func variar_color(c: Color) -> Color:
	return Color(
		clamp(c.r + randf_range(-variacion, variacion), 0, 1),
		clamp(c.g + randf_range(-variacion, variacion), 0, 1),
		clamp(c.b + randf_range(-variacion, variacion), 0, 1),
		c.a
	)

func get_solucion():
	return solucion_generada
