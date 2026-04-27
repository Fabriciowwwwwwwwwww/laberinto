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
	add_to_group("puzzle_party")
	cinematica.set_puzzle(self)
	randomize()
	
	cronometro.timeout.connect(_on_timer_tick)
	set_process(false)

	objetos = zona_objetos.get_children()

	# 1. Generar lógica
	generar_solucion()
	configurar_slots()
	
	# 🔥 AJUSTE 1: Posicionar los objetos a la izquierda ANTES de la intro
	generar_objetos_desordenados() 
	
	# 2. Mandar solución a cinemática
	cinematica.set_solucion(solucion_actual)

	# 3. Esperar intro
	await iniciar_intro()

func iniciar_intro():
	if cinematica.has_method("ejecutar_secuencia_intro"):
		await cinematica.ejecutar_secuencia_intro()
	
	_iniciar_juego()

# -------------------------
func generar_solucion():
	solucion_actual = objetos.duplicate()
	solucion_actual.shuffle()
	for i in range(solucion_actual.size()):
		var obj := solucion_actual[i] as ItemOrden
		if obj: obj.id_correcto = i

func configurar_slots():
	var screen_size = get_viewport_rect().size
	var margen := 120
	for i in range(slots.size()):
		var slot = slots[i]
		slot.id_correcto = i
		var pos = Vector2(randf_range(margen, screen_size.x - margen), randf_range(margen, screen_size.y - margen))
		slot.global_position = pos

# -------------------------
func _iniciar_juego():
	print("🎮 INICIANDO JUEGO")
	
	# 🔥 AJUSTE 2: Asegurar que estén en su sitio al arrancar el contador
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
	jugando = false
	cronometro.stop()
	set_process(false)

	for item in objetos:
		if is_instance_valid(item): item.set_process_input(false)

	# 2. ⏱️ PAUSA PARA VER EL RESULTADO (2 segundos)
	await get_tree().create_timer(2.0).timeout 

	# 3. 🧹 RESET VISUAL (Ocurre mientras empieza el diálogo)
	resultado_label.text = "Resultado: 0%"
	porcentaje = 0.0
	
	generar_solucion()
	configurar_slots()
	generar_objetos_desordenados() # Esto los devuelve a la izquierda al perder
	
	cinematica.set_solucion(solucion_actual)

	# 4. MOSTRAR CINEMÁTICA (Diálogo)
	await cinematica.ejecutar_derrota()

	# 5. RE-INICIAR
	_iniciar_juego()

# -------------------------
func generar_objetos_desordenados():
	var y_offset := 0
	# Usamos la lista de objetos o la solucion para iterar
	for item in solucion_actual:
		if is_instance_valid(item):
			item.posicion_inicial = Vector2(20, y_offset)
			item.global_position = item.posicion_inicial
			y_offset += 130

func evaluar_resultado():
	var correctos: int = 0
	var total: int = slots.size()

	for slot in slots:
		var mejor_item: ItemOrden = null
		var mejor_dist: float = 999999.0
		var centro_slot = slot.global_position + slot.size / 2

		for item in objetos:
			var obj := item as ItemOrden
			if not is_instance_valid(obj): continue
			var centro_obj = obj.global_position + obj.size / 2
			var dist = centro_obj.distance_to(centro_slot)
			if dist < mejor_dist:
				mejor_dist = dist
				mejor_item = obj

		if mejor_item != null and mejor_dist < distancia_max:
			if mejor_item.id_correcto == slot.id_correcto:
				correctos += 1

	porcentaje = (float(correctos) / float(total)) * 100.0 if total > 0 else 0.0
	resultado_label.text = "Resultado: " + str(int(porcentaje)) + "%"

	if porcentaje >= 70:
		print("✅ Victoria")
	else:
		await manejar_derrota()

func _on_timer_tick():
	if not jugando: return
	tiempo_restante -= 1
	label_cronometro.text = "Tiempo: " + str(tiempo_restante)
	if tiempo_restante <= 0: manejar_derrota()

func _on_aceptar_pressed():
	if jugando: evaluar_resultado()
