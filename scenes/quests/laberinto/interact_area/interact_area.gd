@tool
class_name InteractArea
extends Area2D

signal interaction_started(player, from_right: bool)
signal interaction_ended

@export var marker: Marker2D
@export var disabled := false

const INDICATOR_SCENE = preload("res://scenes/quests/laberinto/interact_area/interact_indicator.tscn")

var _indicator: Node2D
var player_inside := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	monitoring = true
	monitorable = true

	collision_layer = 1
	collision_mask = 1

	if marker == null:
		marker = Marker2D.new()
		marker.position = Vector2(0, -64)
		add_child(marker)

	_indicator = INDICATOR_SCENE.instantiate()
	marker.add_child(_indicator)

	_indicator.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if disabled:
		return

	if body.is_in_group("player"):
		player_inside = true

		body.set_current_interact_area(self) # 🔥 FALTABA ESTO

		if _indicator:
			_indicator.visible = true
			_indicator.set_bouncing(true)
			_indicator.z_index = 100

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false

		if _indicator:
			_indicator.set_bouncing(false)
			_indicator.visible = false


func start_interaction(player, from_right: bool):
	if disabled:
		return

	interaction_started.emit(player, from_right)


func end_interaction():
	interaction_ended.emit()
