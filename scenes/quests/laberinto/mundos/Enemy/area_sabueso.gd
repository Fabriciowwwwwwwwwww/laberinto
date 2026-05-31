extends Area2D

@export var spawner_path: NodePath

var spawner

func _ready():

	spawner = get_node(spawner_path)

func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):
		return

	if spawner:

		spawner.iniciar_oleada()
