extends Area2D

@onready var xp_manager = get_parent().get_node("XPManager")

func _ready():
	print("🧲 XP Collector listo")

func _on_body_entered(body):
	print("⚡ Algo entró al área:", body.name)

	if body.is_in_group("xp_orb"):
		print("✅ Es una XP orb")

		if xp_manager:
			print("➕ Sumando XP:", body.xp_value)
			xp_manager.agregar_experiencia(body.xp_value)
		else:
			print("❌ XP Manager no encontrado")

		print("💥 Eliminando orb")
		body.queue_free()
