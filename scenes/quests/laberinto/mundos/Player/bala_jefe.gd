extends Area2D

var direction := Vector2.ZERO
var speed := 0.0

func _ready() -> void:
	# Nos aseguramos de que la bala limpie su memoria si sale de la pantalla
	# (Opcional: puedes añadir un VisibilityNotifier2D para esto)
	pass

# 🛠️ Esta es la función que tu Boss estaba buscando y no encontraba:
func setup(dir: Vector2, bullet_speed: float) -> void:
	direction = dir.normalized()
	speed = bullet_speed
	
	# Opcional: Rotar la bala en la dirección del movimiento
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# Mover la bala de forma constante en la dirección asignada
	global_position += direction * speed * delta

# Conecta la señal "body_entered" desde el editor de Godot a esta función,
# o hazlo por código si prefieres para dañar al jugador.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		if body.has_method("take_damage"):
			body.take_damage(10.0) # O el daño que consideres
		elif body.has_signal("damage"):
			body.emit_signal("damage", 10.0)
			
		queue_free() # Destruir la bala al impactar al jugador

	# Destruir la bala si choca contra una pared/tilemap
	elif body is TileMapLayer or body.name == "TileMap" or body is StaticBody2D:
		queue_free()
