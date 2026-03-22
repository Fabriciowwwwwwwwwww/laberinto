extends Node2D
@export var enemigo_escena: PackedScene
@export var tiempo_entre_oleadas: float = 30.0  # Más rápido que antes (antes 30.0)
@export var radio_min: float = 200.0
@export var radio_max: float = 300.0
@export var max_enemigos: int = 11
@onready var jugador = get_tree().get_first_node_in_group("player")
func _ready():
	spawn_enemigos()
	$Timer.wait_time = tiempo_entre_oleadas
	$Timer.timeout.connect(_on_Timer_timeout) # <- Asegura conexión
	$Timer.start()
func _on_Timer_timeout():
	spawn_enemigos()

func contar_enemigos_actuales() -> int:
	var total = 0
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		if nodo.is_inside_tree():
			total += 1
	return total

func spawn_enemigos():
	if jugador == null:
		return

	var enemigos_actuales = contar_enemigos_actuales()
	if enemigos_actuales >= max_enemigos:
		return

	# Aumentar la probabilidad de aparición de más enemigos
	var probabilidad_extra = clamp((1.0 - float(enemigos_actuales) / max_enemigos), 0.0, 1.0)
	var cantidad = randi_range(2, 4)  # Aumentado el mínimo y máximo

	if randf() < 0.20 + probabilidad_extra * 0.1:  # Probabilidad más alta
		cantidad = 5

	# Ajustar para no exceder el máximo permitido
	cantidad = min(cantidad, max_enemigos - enemigos_actuales)


	for i in range(cantidad):
		var enemigo = enemigo_escena.instantiate()
		var angulo = randf() * TAU
		var distancia = randf_range(radio_min, radio_max)
		var offset = Vector2.RIGHT.rotated(angulo) * distancia
		enemigo.global_position = jugador.global_position + offset
		get_tree().current_scene.call_deferred("add_child", enemigo)
		enemigo.add_to_group("enemigos")
