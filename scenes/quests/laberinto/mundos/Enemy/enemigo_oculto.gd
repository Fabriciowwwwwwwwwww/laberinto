extends EnemyBase

@onready var area_activacion: Area2D = $AreaActivacion

var activado := false
var emergiendo := false

func _ready():

	super()

	# empieza invisible
	animated_sprite_2d.visible = false

	# detectar jugador
	area_activacion.body_entered.connect(_on_body_entered)

func _on_body_entered(body):

	if activado:
		return

	if body.is_in_group("player"):

		activado = true

		aparecer()

func aparecer():

	emergiendo = true

	# mostrar enemigo
	animated_sprite_2d.visible = true

	# puerta
	animated_sprite_2d.play("puerta")

	await animated_sprite_2d.animation_finished

	# emerger
	animated_sprite_2d.play("emerger")

	await animated_sprite_2d.animation_finished

	# idle
	animated_sprite_2d.play("idle")

	emergiendo = false

func _physics_process(delta):

	# no hace nada hasta activarse
	if not activado:
		return

	# mientras emerge no se mueve
	if emergiendo:

		velocity = Vector2.ZERO

		move_and_slide()

		return

	# ejecutar IA NORMAL del enemigo base
	super._physics_process(delta)
