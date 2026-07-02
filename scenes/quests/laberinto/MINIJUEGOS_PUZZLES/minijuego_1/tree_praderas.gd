@tool
extends Node2D

@export var sprite_frames: SpriteFrames:
	set(value):
		sprite_frames = value
		_update_sprite()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_update_sprite()

func _update_sprite() -> void:
	if !is_node_ready():
		return

	if sprite_frames != null:
		sprite.sprite_frames = sprite_frames

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
