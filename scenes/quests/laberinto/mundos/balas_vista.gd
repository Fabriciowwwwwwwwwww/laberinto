extends CanvasLayer

# 🔸 UI extra
@onready var indicador: Label = $Control/Panel/indicador
@onready var numero_balas: Label = $Control/Panel/numero_balas_label

@onready var imagenes_balas: Array[TextureRect] = [
	$Control/Panel/BalasContainer/b1,
	$Control/Panel/BalasContainer/b2,
	$Control/Panel/BalasContainer/b3,
	$Control/Panel/BalasContainer/b4,
	$Control/Panel/BalasContainer/b5,
	$Control/Panel/BalasContainer/b6
]

@onready var recarga_bar: ProgressBar = $Control/Panel/RecargaBar

var balas: int = 6
var recargando: bool = false
var tiempo_recarga: float = 1.0

# 🔸 animación puntos
var puntos_timer: float = 0
var puntos_estado: int = 0

func _ready() -> void:
	for img in imagenes_balas:
		img.visible = true
	
	recarga_bar.visible = false
	recarga_bar.min_value = 0
	recarga_bar.max_value = tiempo_recarga
	recarga_bar.value = 0
	
	actualizar_ui()
	indicador.text = "¡Pistola lista!"

func procesar_disparo() -> bool:
	if balas > 0:
		balas -= 1
		imagenes_balas[balas].visible = false
		
		actualizar_ui()
		
		if not recargando:
			recargando = true
			recarga_bar.visible = true
			recarga_bar.value = 0
			
			puntos_timer = 0
			puntos_estado = 1
		
		return true
	else:
		return false

func _process(delta: float) -> void:
	if recargando:
		recarga_bar.value += delta
		
		# 🔸 animación puntos
		puntos_timer += delta
		if puntos_timer >= 0.5:
			puntos_timer = 0
			puntos_estado += 1
			if puntos_estado > 3:
				puntos_estado = 1
		
		indicador.text = "Recargando" + ".".repeat(puntos_estado)
		
		if recarga_bar.value >= tiempo_recarga:
			recarga_bar.value = 0.0
			
			if balas < 6:
				imagenes_balas[balas].visible = true
				balas += 1
				actualizar_ui()
			
			if balas >= 6:
				recargando = false
				recarga_bar.visible = false
				indicador.text = "¡Pistola lista!"

func actualizar_ui() -> void:
	numero_balas.text = " %d/6" % balas
