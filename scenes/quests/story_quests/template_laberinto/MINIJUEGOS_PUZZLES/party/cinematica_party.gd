extends Node2D
class_name CinematicaOrden

signal cinematica_terminada

# 🎬 DIALOGOS
@export var dialogue_intro: DialogueResource
@export var dialogue_inicio_juego: DialogueResource

# 🧠 DATOS
var solucion: Array = []

# 🎨 REFERENCIAS
@onready var contenedor = $CanvasLayer/ContenedorSolucion
@onready var label_titulo = $CanvasLayer/LabelTitulo
@onready var label_countdown = $CanvasLayer/LabelCuentaAtras

# ⏱️ CONFIG
@export var tiempo_mostrar := 3.0
@export var tiempo_countdown := 3

# -------------------------
func _ready():
	add_to_group("cinematica")
	await iniciar_cinematica()

# -------------------------
func set_solucion(sol: Array):
	solucion = sol.duplicate()

# -------------------------
func iniciar_cinematica():
	await get_tree().process_frame

	print("🎬 Cinemática Orden: INICIO")

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
	label_titulo.text = "MEMORIZA EL ORDEN"

	# limpiar anterior
	for c in contenedor.get_children():
		c.queue_free()

	await get_tree().process_frame

	# crear visual
	for item_data in solucion:

		var textura = null

		# 🔥 SOPORTA PackedScene
		if item_data is PackedScene:
			var instancia = item_data.instantiate()

			if instancia is Sprite2D:
				textura = instancia.texture

			elif instancia.has_method("get_texture"):
				textura = instancia.get_texture()

		# 🔥 SOPORTA Texture directa
		elif item_data is Texture2D:
			textura = item_data

		# ❌ si no hay textura, saltar
		if textura == null:
			continue

		var sprite = TextureRect.new()
		sprite.texture = textura
		sprite.custom_minimum_size = Vector2(120, 120)
		sprite.expand = true

		# ✨ fade inicial
		sprite.modulate.a = 0

		contenedor.add_child(sprite)

		# ✨ animación aparición
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1, 0.4)

# -------------------------
func cuenta_regresiva():
	label_countdown.visible = true

	for i in range(tiempo_countdown, 0, -1):
		label_countdown.text = str(i)

		# ✨ pequeño efecto escala
		label_countdown.scale = Vector2(1.5, 1.5)

		var tween = create_tween()
		tween.tween_property(label_countdown, "scale", Vector2.ONE, 0.3)

		await get_tree().create_timer(1.0).timeout

	label_countdown.text = "¡YA!"

	# ✨ efecto final
	label_countdown.scale = Vector2(2, 2)
	await get_tree().create_timer(0.5).timeout

	label_countdown.visible = false
