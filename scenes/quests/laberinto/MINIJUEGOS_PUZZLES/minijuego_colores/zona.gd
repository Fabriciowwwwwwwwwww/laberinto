extends Polygon2D

@export var id_color: int = 0

var color_actual: Color = Color.WHITE

# 🔥 IMPORTANTE
# NO resetear automáticamente aquí
func _ready():
	color_actual = color

# =========================
# APLICAR COLOR
# =========================
func aplicar_color(nuevo_color):

	modulate = Color.WHITE

	color = nuevo_color
	color_actual = nuevo_color

# =========================
# RESET
# =========================
func resetear():

	texture = null
	modulate = Color.WHITE
	self_modulate = Color.WHITE

	color = Color(0.3, 0.3, 0.3, 0.5)
	color_actual = color
