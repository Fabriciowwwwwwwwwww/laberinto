extends Control

enum ShopCategory { SKIN, BAILE, PODER }
@export var animacion_duracion := 0.6
@export var animacion_delay := 0.0
@export var posicion_inicial_y := -991.0
@export var posicion_final_y := 76.0
@export var tipo_transicion := Tween.TRANS_CUBIC
@export var tipo_ease := Tween.EASE_OUT



@onready var content = $GridContainer
@onready var label_categoria = $CategoryLabel
@onready var preview = $PanelPreview

@export var skins: Array[PackedScene]
@export var bailes: Array[PackedScene]
@export var poderes: Array[PackedScene]

@export var columnas := 4
@export var filas_visibles := 2
@export var alto_fila := 191.0
@export var offset_y_inicial := -30.0
@export var posiciones_x := [-539, -180, 180, 539]

@export var escala_seleccion := 1.2
@export var color_seleccion := Color(1, 0.82, 0.05)
@export var color_normal := Color.WHITE

var categoria_actual = ShopCategory.SKIN
var lista_actual: Array = []

var indice := 0
var pagina_actual := 0
var items_por_pagina := 8

# -------------------------
func _ready():
	items_por_pagina = columnas * filas_visibles

	# 🔥 FORZAR POSICIÓN INICIAL
	position.y = posicion_inicial_y

	cargar_categoria()

	# 🔥 esperar 1 frame para que sí se vea la animación
	await get_tree().process_frame

	animar_entrada()

func animar_entrada():
	var tween = create_tween()

	# 🔥 delay opcional
	if animacion_delay > 0:
		tween.tween_interval(animacion_delay)

	tween.tween_property(self, "position:y", posicion_final_y, animacion_duracion)\
		.set_trans(tipo_transicion)\
		.set_ease(tipo_ease)
# -------------------------
func _input(event):
	if event.is_action_pressed("ui_right"):
		cambiar_categoria(1)
	elif event.is_action_pressed("ui_left"):
		cambiar_categoria(-1)
	elif event.is_action_pressed("ui_down"):
		mover(1)
	elif event.is_action_pressed("ui_up"):
		mover(-1)
	elif event.is_action_pressed("ui_accept"):
		seleccionar()

# -------------------------
func cambiar_categoria(dir):
	categoria_actual = (categoria_actual + dir) % 3
	if categoria_actual < 0:
		categoria_actual = 2

	indice = 0
	pagina_actual = 0

	cargar_categoria()

# -------------------------
func cargar_categoria():
	for c in content.get_children():
		c.queue_free()

	await get_tree().process_frame  # 🔥 IMPORTANTE

	match categoria_actual:
		ShopCategory.SKIN:
			lista_actual = skins
			label_categoria.text = "SKIN"
		ShopCategory.BAILE:
			lista_actual = bailes
			label_categoria.text = "BAILE"
		ShopCategory.PODER:
			lista_actual = poderes
			label_categoria.text = "PODER"

	for item in lista_actual:
		var nodo = item.instantiate()
		content.add_child(nodo)

		# 🔥 RESET VISUAL COMPLETO
		nodo.visible = true
		nodo.modulate = Color.WHITE
		nodo.scale = Vector2.ONE
		nodo.set_anchors_preset(Control.PRESET_TOP_LEFT)

	indice = 0
	pagina_actual = 0

	await get_tree().process_frame  # 🔥 clave

	actualizar_vista()
	actualizar_preview()

# -------------------------
func mover(dir):
	if lista_actual.is_empty():
		return

	var anterior = indice
	indice += dir

	if indice < 0:
		indice = lista_actual.size() - 1
	elif indice >= lista_actual.size():
		indice = 0

	# 🔥 calcular pagina correctamente
	pagina_actual = int(indice / items_por_pagina)

	print("[SHOP]:", anterior, "→", indice, " | PAG:", pagina_actual)

	actualizar_vista()
	actualizar_preview()

# -------------------------
func actualizar_vista():
	var inicio = pagina_actual * items_por_pagina
	var fin_real = min(inicio + items_por_pagina, lista_actual.size())

	var ancho_item = 180
	var alto_item = 180
	var espacio_x = 60
	var espacio_y = 60

	# 🔥 USAR EL GRID COMO REFERENCIA (CLAVE)
	var area = content.size

	var ancho_total = columnas * ancho_item + (columnas - 1) * espacio_x
	var alto_total = filas_visibles * alto_item + (filas_visibles - 1) * espacio_y

	# 🔥 CENTRADO REAL DENTRO DEL PANEL
	var start_x = (area.x - ancho_total) / 2
	var start_y = (area.y - alto_total) / 2

	for i in range(content.get_child_count()):
		var item = content.get_child(i)

		if i >= inicio and i < fin_real:
			item.visible = true

			var local_index = i - inicio
			var fila = int(local_index / columnas)
			var col = int(local_index % columnas)

			var x = start_x + col * (ancho_item + espacio_x)
			var y = start_y + fila * (alto_item + espacio_y)

			item.position = Vector2(x, y)

			# 🔥 SELECCIÓN
			if i == indice:
				item.scale = Vector2.ONE * escala_seleccion
				item.modulate = color_seleccion
			else:
				item.scale = Vector2.ONE
				item.modulate = color_normal
		else:
			item.visible = false

# -------------------------
func actualizar_preview():
	if lista_actual.is_empty():
		return

	for c in preview.get_children():
		c.queue_free()

	var nuevo = lista_actual[indice].instantiate()
	preview.add_child(nuevo)

	nuevo.scale = Vector2(3,3)
	nuevo.position = Vector2.ZERO

# -------------------------
func seleccionar():
	print("[SHOP]: Seleccionado:", indice)

func _on_comprar_button_pressed():
	print("[SHOP]: Comprado:", indice)
