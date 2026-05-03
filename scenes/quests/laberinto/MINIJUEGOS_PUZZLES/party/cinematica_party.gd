extends CinematicaBase
class_name CinematicaOrden

@onready var canvas: CanvasLayer = $CanvasLayer
@onready var contenedor: Control = $CanvasLayer/ContenedorSolucion
@onready var label_countdown: Label =%LabelCuentaAtras

@export var tiempo_mostrar: float = 10
var puzzle_ref: Node = null
var solucion: Array = []
func _ready():
	if label_countdown:
		label_countdown.visible = false
func set_solucion(sol: Array):
	solucion = sol.duplicate()

func set_puzzle(p):
	puzzle_ref = p

func ejecutar_secuencia_intro():
	if canvas: canvas.visible = true
	await reproducir_dialogo(dialogue_intro)
	await mostrar_solucion()
	ejecutar_cuenta_atras()
	await get_tree().create_timer(tiempo_mostrar).timeout
	if canvas: canvas.visible = false
	cinematica_terminada.emit()

func ejecutar_derrota():
	if canvas: canvas.visible = true
	
	# Mostrar la solución generada para la siguiente ronda
	await mostrar_solucion()
	
	# Diálogo de perder (el jugador ve la solución mientras lee)
	await reproducir_dialogo(dialogue_perder)
	ejecutar_cuenta_atras()
	await get_tree().create_timer(tiempo_mostrar).timeout
	if canvas: canvas.visible = false

func mostrar_solucion():
	for c in contenedor.get_children():
		c.free()

	await get_tree().process_frame

	if puzzle_ref == null or solucion.is_empty(): return

	var zona_slots = puzzle_ref.get_node_or_null("ZonaSlots")
	var slots = zona_slots.get_children()

	for i in range(solucion.size()):
		var item = solucion[i]
		if not is_instance_valid(item) or not item.textura: continue

		var sprite := TextureRect.new()
		sprite.texture = item.textura
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.custom_minimum_size = Vector2(100, 100)
		
		contenedor.add_child(sprite)

		# Posicionar sobre el slot (que ya fue movido aleatoriamente en el puzzle)
		if i < slots.size():
			sprite.global_position = slots[i].global_position

func ejecutar_cuenta_atras():
	if not label_countdown:
		print("❌ Label no encontrado")
		return

	# 🔴 OCULTAR cronómetro del juego
	if puzzle_ref:
		puzzle_ref.ocultar_cronometro()

	# 🟡 Mostrar contador
	label_countdown.visible = true
	label_countdown.modulate = Color(1,1,1,1)

	for i in range(10, 0, -1):
		label_countdown.text = str(i)
		label_countdown.queue_redraw()
		await get_tree().create_timer(1.0).timeout

	# 🔴 Ocultar contador
	label_countdown.visible = false

	# 🟢 VOLVER a mostrar cronómetro del juego
	if puzzle_ref:
		puzzle_ref.mostrar_cronometro()
func ejecutar_victoria():
	if canvas: canvas.visible = true
	
	# Mostrar solución (opcional, pero queda bien)
	await mostrar_solucion()

	# Diálogo de ganar
	await reproducir_dialogo(dialogue_ganar)
	cambiar_escena()
