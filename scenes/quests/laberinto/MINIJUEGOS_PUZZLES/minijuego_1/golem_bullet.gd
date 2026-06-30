extends Area2D

@export var speed := 250.0
var direction := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if Gamestateminijuegos.changing_scene:
		return

	if body.is_in_group("player"):
		print("💥 Player golpeado")
		get_tree().reload_current_scene()
		queue_free()
