extends Area2D

@export var dano := 10.0

var direction := Vector2.ZERO
var speed := 0.0

func _ready() -> void:
	pass

func setup(dir: Vector2, bullet_speed: float) -> void:
	direction = dir.normalized()
	speed = bullet_speed

	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body):
	print("CHOQUE CON: ", body.name)

	if body.is_in_group("player") or body.is_in_group("player_2"):
		print("GOLPEO AL JUGADOR")

		if body.has_method("recibir_daño"):
			print("TIENE recibir_daño")
			body.recibir_daño(dano)
		elif body.has_method("recibir_dano"):
			print("TIENE recibir_dano")
			body.recibir_dano(dano)

		queue_free()

	# Destruir la bala si golpea una pared
	elif body is TileMapLayer or body.name == "TileMap" or body is StaticBody2D:
		queue_free()
