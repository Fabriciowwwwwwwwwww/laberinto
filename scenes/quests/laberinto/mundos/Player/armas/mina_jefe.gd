extends Area2D

@export var tiempo_explosion := 5.0
@export var radio_explosion := 150.0
@export var dano := 10

@onready var timer: Timer = $Timer

var player

func _ready():
	player = get_tree().get_first_node_in_group("player")

	timer.wait_time = tiempo_explosion
	timer.one_shot = true
	timer.timeout.connect(explotar)
	timer.start()

func explotar():
	if player:
		var distancia = global_position.distance_to(player.global_position)

		if distancia <= radio_explosion:
			if player.has_method("recibir_daño"):
				player.recibir_daño(dano)
			elif player.has_method("recibir_dano"):
				player.recibir_dano(dano)

	if $AnimatedSprite2D.sprite_frames.has_animation("explosion"):
		$AnimatedSprite2D.play("explosion")
		await $AnimatedSprite2D.animation_finished

	queue_free()
