extends EnemyBase

@onready var area_activacion: Area2D = $AreaActivacion
@export var vida_inicial := 120

var activado := false
var emergiendo := false
var invulnerable_spawn := true


func _ready():
	super()

	add_to_group("enemy")

	# 🔥 IMPORTANTE: ocultar al inicio
	animated_sprite_2d.visible = false

	# 🔥 conectar activación
	area_activacion.body_entered.connect(_on_body_entered)

	vida_max = vida_inicial
	vida = vida_inicial
	actualizar_ui_vida()


func _on_body_entered(body):
	if activado:
		return

	if body.is_in_group("player"):
		activado = true
		aparecer()


func aparecer():
	emergiendo = true
	invulnerable_spawn = true

	# mostrar sprite
	animated_sprite_2d.visible = true

	call_deferred("_mostrar_ui_segura")

	animated_sprite_2d.play("puerta")
	await animated_sprite_2d.animation_finished

	animated_sprite_2d.play("emerger")
	await animated_sprite_2d.animation_finished

	animated_sprite_2d.play("idle")

	emergiendo = false

	await get_tree().create_timer(0.2).timeout
	invulnerable_spawn = false


func _mostrar_ui_segura():
	await get_tree().process_frame
	vida_bar.visible = true
	vida_etiqueta.visible = true
	actualizar_ui_vida()


func recibir_daño(cantidad: int) -> void:
	if invulnerable_spawn:
		return

	super.recibir_daño(cantidad)


func _physics_process(delta):
	if not activado:
		return

	if emergiendo:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	super._physics_process(delta)
