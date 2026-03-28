class_name VolumeSlider
extends HSlider

@export var bus_name: String


func _ready() -> void:
	min_value = -40
	max_value = 0
	step = 0.1
	
	value_changed.connect(_on_value_changed)
	
	_refresh()
	
	# 🔥 APLICAR el valor al iniciar
	_on_value_changed(value)


func _on_visibility_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if bus_name != "":
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index != -1:
			var vol = AudioServer.get_bus_volume_db(bus_index)
			value = vol
			
			# 🔥 APLICAR el volumen también
			AudioServer.set_bus_volume_db(bus_index, vol)


func _on_value_changed(new_value: float) -> void:
	print("SLIDER:", new_value)  # 👈 DEBUG
	
	if bus_name != "":
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index != -1:
			AudioServer.set_bus_volume_db(bus_index, new_value)
