extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func abrir_candado():
	anim.play("abierto")

	await anim.animation_finished

	caer()

func caer():
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 200, 0.5)
	await tween.finished

	queue_free()
