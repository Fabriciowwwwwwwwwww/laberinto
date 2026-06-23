extends Area2D

@export var poder: float = 20
@export var speed: float = 500.0

var direction: Vector2 = Vector2.ZERO
var impactando := false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.play("bala_recorrido")

	# Conectar señal solo si no está conectada
	if not animated_sprite_2d.animation_finished.is_connected(_on_animacion_terminada):
		animated_sprite_2d.animation_finished.connect(_on_animacion_terminada)

func _process(delta: float) -> void:
	if not impactando:
		position += direction * speed * delta

func _on_body_entered(body: Node) -> void:

	# Evita múltiples impactos
	if impactando:
		return

	if body.is_in_group("enemy"):

		if body.has_method("recibir_daño"):
			body.recibir_daño(poder)

		_reproducir_impacto()

	elif body.is_in_group("wall") or body is TileMap:
		_reproducir_impacto()

func _reproducir_impacto() -> void:
	impactando = true

	# Desactivar colisión de forma segura
	set_deferred("monitoring", false)

	animated_sprite_2d.play("impacto_bala")

func _on_animacion_terminada() -> void:

	if animated_sprite_2d.animation == "impacto_bala":
		queue_free()
