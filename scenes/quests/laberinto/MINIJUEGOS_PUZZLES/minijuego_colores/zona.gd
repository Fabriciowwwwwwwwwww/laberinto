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
func aplicar_color(nuevo_color: Color):

	color = nuevo_color
	color_actual = nuevo_color

# =========================
# RESET
# =========================
func resetear():

	color = Color(0.3, 0.3, 0.3, 0.5)
	color_actual = color
