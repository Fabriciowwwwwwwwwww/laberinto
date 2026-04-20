extends Node2D

# 🎬 CINEMÁTICA
@onready var cinematica = $"../../cinematica_party"

# 🎯 OBJETOS DESDE INSPECTOR
@export var objetos: Array[PackedScene]

# 🧩 REFERENCIAS
@onready var zona_objetos = $ZonaObjetos
@onready var slots = $ZonaSlots.get_children()
@onready var resultado_label = $ResultadoLabel

# 🧠 DATA
var solucion_actual: Array = []

# -------------------------
func _ready():
	randomize()

	# ❌ no iniciar gameplay aún
	set_process(false)

	# 🔍 seguridad
	if cinematica == null:
		push_error("❌ No se encontró cinematica_party")
		return

	# 🔀 generar orden aleatorio
	generar_solucion()

	# 🎯 configurar slots
	configurar_slots()

	# 🎬 enviar solución a cinemática
	cinematica.set_solucion(solucion_actual)

	# 🔗 esperar fin de cinemática
	cinematica.cinematica_terminada.connect(_iniciar_juego)

# -------------------------
# 🔀 GENERAR ORDEN ALEATORIO
func generar_solucion():
	solucion_actual = objetos.duplicate()
	solucion_actual.shuffle()

# -------------------------
# 🎯 CONFIGURAR SLOTS
func configurar_slots():
	for i in range(slots.size()):
		slots[i].id_correcto = i

# -------------------------
# 🎮 INICIO DEL JUEGO
func _iniciar_juego():
	print("🎮 INICIA PUZZLE")

	generar_objetos_desordenados()

	set_process(true)

# -------------------------
# 🎲 GENERAR OBJETOS RANDOM
func generar_objetos_desordenados():
	# limpiar
	for c in zona_objetos.get_children():
		c.queue_free()

	await get_tree().process_frame

	var area_size = zona_objetos.size

	for i in range(solucion_actual.size()):
		var escena = solucion_actual[i]
		var instancia = escena.instantiate()

		# 🔥 asignar ID correcto
		instancia.id_correcto = i

		zona_objetos.add_child(instancia)

		# 🎲 posición aleatoria
		instancia.position = Vector2(
			randf_range(0, area_size.x - 120),
			randf_range(0, area_size.y - 120)
		)

# -------------------------
# 📊 EVALUACIÓN
func evaluar_resultado():
	var correctos = 0
	var total = slots.size()

	for slot in slots:
		if slot.item_actual != null:
			if slot.item_actual.id_correcto == slot.id_correcto:
				correctos += 1

	var porcentaje = 0.0
	if total > 0:
		porcentaje = float(correctos) / total * 100

	resultado_label.text = "Resultado: " + str(int(porcentaje)) + "%"

	if porcentaje >= 70:
		print("✅ GANASTE")
	else:
		print("❌ PERDISTE")
