extends Node2D
class_name CinematicaOrden

signal cinematica_terminada

# 🎬 DIALOGOS
@export var dialogue_intro: DialogueResource
@export var dialogue_inicio_juego: DialogueResource

# 🧠 DATOS
var solucion: Array = []

# 🎨 REFERENCIAS
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var contenedor: Control = $CanvasLayer/ContenedorSolucion
@onready var label_titulo: Label = $CanvasLayer/LabelTitulo
@onready var label_countdown: Label = $CanvasLayer/LabelCuentaAtras

# ⏱️ CONFIG
@export var tiempo_mostrar := 3.0
@export var tiempo_countdown := 3

# -------------------------
func _ready():
	add_to_group("cinematica")

	# 🔥 seguridad (evita null)
	if contenedor == null:
		push_error("❌ ContenedorSolucion no encontrado")
	if label_titulo == null:
		push_error("❌ LabelTitulo no encontrado")
	if label_countdown == null:
		push_error("❌ LabelCuentaAtras no encontrado")

	await iniciar_cinematica()

# -------------------------
func set_solucion(sol: Array):
	solucion = sol.duplicate()

# -------------------------
func iniciar_cinematica():
	await get_tree().process_frame

	print("🎬 Cinemática Orden: INICIO")

	# 🔥 mostrar UI
	canvas.visible = true

	# 🎬 DIÁLOGO INTRO
	if dialogue_intro:
		var balloon = DialogueManager.show_dialogue_balloon(
			dialogue_intro, "", [self]
		)
		if balloon:
			await DialogueManager.dialogue_ended

	# 🎨 MOSTRAR SOLUCIÓN
	await mostrar_solucion()

	# ⏳ TIEMPO PARA MEMORIZAR
	await get_tree().create_timer(tiempo_mostrar).timeout

	# ⏳ CUENTA REGRESIVA
	await cuenta_regresiva()

	# 🔥 OCULTAR TODO (IMPORTANTE)
	canvas.visible = false

	# 🎬 DIÁLOGO INICIO JUEGO
	if dialogue_inicio_juego:
		var balloon2 = DialogueManager.show_dialogue_balloon(
			dialogue_inicio_juego, "", [self]
		)
		if balloon2:
			await DialogueManager.dialogue_ended

	print("🎮 INICIA MINIJUEGO")
	cinematica_terminada.emit()

# -------------------------
func mostrar_solucion():
	if label_titulo:
		label_titulo.text = "MEMORIZA EL ORDEN"

	# limpiar anterior
	for c in contenedor.get_children():
		c.queue_free()

	await get_tree().process_frame

	# 🔥 crear visual de solución
	for item_data in solucion:

		var textura: Texture2D = null

		# 🔥 PackedScene (tus objetos)
		if item_data is PackedScene:
			var instancia = item_data.instantiate()

			if instancia is Sprite2D:
				textura = instancia.texture

			elif instancia.has_method("get_texture"):
				textura = instancia.get_texture()

			instancia.queue_free() # evitar leaks

		# 🔥 Texture directa
		elif item_data is Texture2D:
			textura = item_data

		if textura == null:
			continue

		var sprite = TextureRect.new()
		sprite.texture = textura
		sprite.custom_minimum_size = Vector2(120, 120)
		sprite.expand = true
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		# ✨ fade inicial
		sprite.modulate.a = 0

		contenedor.add_child(sprite)

		# ✨ animación
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.4)

# -------------------------
func cuenta_regresiva():
	if label_countdown == null:
		return

	label_countdown.visible = true

	for i in range(tiempo_countdown, 0, -1):
		label_countdown.text = str(i)

		# ✨ animación escala
		label_countdown.scale = Vector2(1.5, 1.5)

		var tween = create_tween()
		tween.tween_property(label_countdown, "scale", Vector2.ONE, 0.3)

		await get_tree().create_timer(1.0).timeout

	label_countdown.text = "¡YA!"
	label_countdown.scale = Vector2(2, 2)

	await get_tree().create_timer(0.5).timeout

	label_countdown.visible = false
