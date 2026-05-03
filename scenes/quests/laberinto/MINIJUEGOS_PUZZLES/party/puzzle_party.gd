extends Node2D

var porcentaje: float = 0.0
var jugando := false
@onready var cinematica = $"../../cinematica_party"
var distancia_max := 120

# ⏱️ UI
@onready var cronometro: Timer = $Cronometro
@onready var label_cronometro: Label = %CronometroLabel
@onready var resultado_label = %ResultadoLabel

# 🧩 REFERENCIAS
@onready var zona_objetos = $zona_objetos
@onready var slots = $ZonaSlots.get_children()

# 🧠 DATA
var objetos: Array = []
var solucion_actual: Array = []
var tiempo_restante := 30

# -------------------------
func _ready():
	print("🚀 READY puzzle_party")

	add_to_group("puzzle_party")
	cinematica.set_puzzle(self)
	randomize()
	
	cronometro.timeout.connect(_on_timer_tick)
	set_process(false)

	objetos = zona_objetos.get_children()
	print("📦 Objetos encontrados:", objetos.size())

	# 1. Generar lógica
	generar_solucion()
	configurar_slots()

	print("🧠 Solución generada:", solucion_actual.size())

	# 🔥 AJUSTE 1
	generar_objetos_desordenados()

	# 2. Mandar solución a cinemática
	print("🎬 Enviando solución a cinemática")
	cinematica.set_solucion(solucion_actual)

	# 3. Esperar intro
	await iniciar_intro()

# -------------------------
func ocultar_cronometro():
	print("🙈 Ocultando cronómetro")
	label_cronometro.visible = false

func mostrar_cronometro():
	print("👁️ Mostrando cronómetro")
	label_cronometro.visible = true

# -------------------------
func iniciar_intro():
	print("🎬 Iniciando intro")
	if cinematica.has_method("ejecutar_secuencia_intro"):
		await cinematica.ejecutar_secuencia_intro()
	
	print("🎮 Pasando a juego")
	_iniciar_juego()

# -------------------------
func generar_solucion():
	print("🔀 Generando solución")

	solucion_actual = objetos.duplicate()
	solucion_actual.shuffle()

	for i in range(solucion_actual.size()):
		var obj := solucion_actual[i] as ItemOrden
		if obj:
			obj.id_correcto = i
			print("✔️ Objeto asignado id:", i)

# -------------------------
func configurar_slots():
	var screen_size = get_viewport_rect().size
	var margen := 120
	var distancia_min := 180 # 🔥 ajusta esto a tu gusto

	var posiciones := []

	for i in range(slots.size()):
		var slot = slots[i]
		slot.id_correcto = i

		var pos := Vector2.ZERO
		var intentos := 0

		while intentos < 50:
			pos = Vector2(
				randf_range(margen, screen_size.x - margen),
				randf_range(margen, screen_size.y - margen)
			)

			var valido := true

			# 🔥 comprobar distancia con otros slots
			for p in posiciones:
				if pos.distance_to(p) < distancia_min:
					valido = false
					break

			if valido:
				break

			intentos += 1

		posiciones.append(pos)
		slot.global_position = pos

# -------------------------
func _iniciar_juego():
	print("🎮 INICIANDO JUEGO")

	generar_objetos_desordenados()

	jugando = true
	tiempo_restante = 30
	label_cronometro.text = "Tiempo: 30"
	
	for item in objetos:
		if is_instance_valid(item):
			item.set_process_input(true)
	
	cronometro.start()
	set_process(true)

# -------------------------
func manejar_derrota():
	print("💀 DERROTA")

	jugando = false
	cronometro.stop()
	set_process(false)

	for item in objetos:
		if is_instance_valid(item):
			item.set_process_input(false)

	await get_tree().create_timer(2.0).timeout 

	print("♻️ Reseteando slots visual")
	resetear_slots_visual()

	resultado_label.text = "Resultado: 0%"
	porcentaje = 0.0
	
	generar_solucion()
	configurar_slots()
	generar_objetos_desordenados()

	print("🎬 Enviando nueva solución tras derrota")
	cinematica.set_solucion(solucion_actual)

	await cinematica.ejecutar_derrota()

	print("🔁 Reiniciando juego")
	_iniciar_juego()

# -------------------------
func generar_objetos_desordenados():
	print("🧩 Desordenando objetos")

	var y_offset := 0

	for item in solucion_actual:
		if is_instance_valid(item):
			item.posicion_inicial = Vector2(20, y_offset)
			item.global_position = item.posicion_inicial
			print("📦 Objeto movido a:", item.global_position)
			y_offset += 130

# -------------------------
func evaluar_resultado():
	print("📊 Evaluando resultado")

	var correctos: int = 0
	var total: int = slots.size()

	# 🧹 Limpiar fantasmas anteriores
	for n in get_tree().get_nodes_in_group("fantasma"):
		n.queue_free()

	for slot in slots:
		var correcto = slot.evaluar(objetos, distancia_max)
		print("🔍 Slot", slot.id_correcto, "correcto:", correcto)
		if correcto:
			correctos += 1

	# 🔥 CREAR FANTASMAS
	for item in objetos:
		var obj := item as ItemOrden
		if not is_instance_valid(obj):
			continue

		var slot_correcto = slots[obj.id_correcto]

		var centro_obj = obj.global_position + obj.size / 2
		var centro_slot = slot_correcto.global_position + slot_correcto.size / 2
		var dist = centro_obj.distance_to(centro_slot)

		var esta_correcto = dist < distancia_max

		if not esta_correcto:
			print("❌ Objeto mal colocado:", obj.id_correcto)

			var copia = obj.duplicate()
			add_child(copia)

			copia.global_position = slot_correcto.global_position
			copia.modulate = Color(1, 0, 0, 0.4)
			copia.set_process_input(false)
			copia.add_to_group("fantasma")

	porcentaje = (float(correctos) / float(total)) * 100.0 if total > 0 else 0.0
	print("📈 Resultado:", porcentaje)

	resultado_label.text = "Resultado: " + str(int(porcentaje)) + "%"

	jugando = false
	cronometro.stop()

	for item in objetos:
		if is_instance_valid(item):
			item.set_process_input(false)

	print("⏳ Mostrando resultado 5 segundos")
	await get_tree().create_timer(5.0).timeout

	print("🧹 Limpiando fantasmas")
	for n in get_tree().get_nodes_in_group("fantasma"):
		n.queue_free()

	if porcentaje >= 70:
		await cinematica.ejecutar_victoria()
	else:
		await manejar_derrota()

# -------------------------
func _on_timer_tick():
	if not jugando:
		return

	tiempo_restante -= 1
	label_cronometro.text = "Tiempo: " + str(tiempo_restante)

	print("⏱️ Tiempo restante:", tiempo_restante)

	if tiempo_restante <= 0:
		print("⌛ Tiempo agotado")
		manejar_derrota()

# -------------------------
func _on_aceptar_pressed():
	print("🟢 Botón evaluar presionado")
	if jugando:
		evaluar_resultado()

# -------------------------
func resetear_slots_visual():
	print("🎨 Reseteando color de slots")

	for slot in slots:
		if slot.has_method("reset_visual"):
			slot.reset_visual()
