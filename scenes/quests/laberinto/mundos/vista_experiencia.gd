extends CanvasLayer

@onready var label = $Panel/LabelXP

var xp_manager

func _ready():
	print("🖥️ UI iniciada")

	var player = get_tree().get_first_node_in_group("player")

	if player:
		xp_manager = player.get_node("XPManager")

		print("🔗 Conectando UI con XPManager")

		xp_manager.connect(
			"experiencia_cambiada",
			_actualizar_ui
		)

		# actualizar al inicio
		_actualizar_ui(xp_manager.experiencia)

	else:
		print("❌ No se encontró el player")


func _actualizar_ui(experiencia):
	print("🖥️ UI actualizada")

	label.text = str(experiencia)
