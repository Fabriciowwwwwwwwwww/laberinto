extends CanvasLayer

# ==================================================
# NODOS
# ==================================================

@onready var portrait = $Portrait
@onready var animation_player = $AnimationPlayer
@onready var flash = $Flash


# ==================================================
# READY
# ==================================================

func _ready():

	# Flash invisible al iniciar
	flash.color = Color.WHITE
	flash.modulate.a = 0.0

	# Animación inicial
	portrait.play("idle")



# ==================================================
# PRUEBAS
# ENTER = flash blanco
# ESPACIO = flash rojo
# S = shake
# ==================================================

func _process(delta):

	if Input.is_action_just_pressed("ui_accept"):

		flash_pantalla()

	if Input.is_key_pressed(KEY_SPACE):

		flash_rojo()

	if Input.is_key_pressed(KEY_S):

		shake()



# ==================================================
# COMANDOS PARA DIALOGOS
# ==================================================

func ejecutar_comando(command):

	match command:

		# ==================================================
		# ANIMACIONES DEL RETRATO
		# ==================================================

		"idle":
			portrait.play("idle")


		"talk":
			portrait.play("talk")


		"crazy":
			portrait.play("crazy")


		"blink":
			portrait.play("blink")


		"stop_anim":
			portrait.stop()



		# ==================================================
		# EFECTOS
		# ==================================================

		"flash":
			flash_pantalla()


		"flash_rojo":
			flash_rojo()


		"shake":
			shake()


		# ==================================================
		# COMBINACIONES
		# ==================================================

		"jumpscare":

			flash_rojo()

			shake()

			portrait.play("crazy")


		"miedo":

			flash_pantalla()

			portrait.play("blink")



# ==================================================
# FLASH BLANCO
# ==================================================

func flash_pantalla():

	flash.color = Color.WHITE

	flash.modulate.a = 1.0

	var tween = create_tween()

	tween.tween_property(
		flash,
		"modulate:a",
		0.0,
		0.25
	)



# ==================================================
# FLASH ROJO
# ==================================================

func flash_rojo():

	flash.color = Color.RED

	flash.modulate.a = 0.8

	var tween = create_tween()

	tween.tween_property(
		flash,
		"modulate:a",
		0.0,
		0.4
	)



# ==================================================
# SHAKE SUAVE
# ==================================================

func shake():

	var original_position = portrait.position

	for i in range(8):

		portrait.position = original_position + Vector2(
			randf_range(-8, 8),
			randf_range(-4, 4)
		)

		await get_tree().create_timer(0.03).timeout

	portrait.position = original_position
