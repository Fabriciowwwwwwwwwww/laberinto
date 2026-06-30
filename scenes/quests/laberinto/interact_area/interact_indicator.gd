extends Node2D

var bouncing := false

@onready var animation_player: AnimationPlayer = %AnimationPlayer


func set_bouncing(new_value: bool) -> void:
	bouncing = new_value

	if animation_player == null:
		return

	if bouncing:
		animation_player.play("bounce")
	else:
		animation_player.play("idle")


func _ready() -> void:
	set_bouncing(false)
