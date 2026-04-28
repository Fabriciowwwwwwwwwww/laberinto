extends CanvasLayer

@onready var barra_vida: TextureProgressBar = $ProgressBar
@onready var label_vida: Label = $vida
@onready var fuego: AnimatedSprite2D = $fuego

# 🔗 Referencia al jugador
@onready var player: Player_l = get_tree().get_first_node_in_group("player") as Player_l

func _ready() -> void:
	if barra_vida:
		barra_vida.min_value = 0
	
	if player:
		barra_vida.max_value = player.vida_maxima
		barra_vida.value = player.vida_actual
	
	fuego.play("idle")
	actualizar_ui()

func _process(delta: float) -> void:
	actualizar_ui()

# 🔄 UI SIEMPRE SINCRONIZADA CON EL PLAYER
func actualizar_ui() -> void:
	if player == null:
		return
	
	# 🔴 Barra
	barra_vida.value = player.vida_actual
	
	# 🔤 Texto
	label_vida.text = "VIDA: %d/%d" % [player.vida_actual, player.vida_maxima]
	
	# 🔥 Efecto visual según vida
	var porcentaje: float = float(player.vida_actual) / float(player.vida_maxima)
	
	# Tamaño
	var escala: float = lerp(0.5, 1.3, porcentaje)
	fuego.scale = Vector2(escala, escala)
	
	# Opacidad + color
	var alpha: float = lerp(0.3, 1.0, porcentaje)
	fuego.modulate = Color(1, porcentaje, porcentaje, alpha)
