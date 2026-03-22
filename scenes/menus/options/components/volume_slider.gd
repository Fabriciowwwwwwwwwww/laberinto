class_name VolumeSlider
extends HSlider

@export var bus_name: String


func _ready() -> void:
	min_value = -40
	max_value = 0
	step = 0.1
	_refresh()


func _on_visibility_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if bus_name != "":
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index != -1:
			value = AudioServer.get_bus_volume_db(bus_index)


func _on_value_changed(new_value: float) -> void:
	if bus_name != "":
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index != -1:
			AudioServer.set_bus_volume_db(bus_index, new_value)
