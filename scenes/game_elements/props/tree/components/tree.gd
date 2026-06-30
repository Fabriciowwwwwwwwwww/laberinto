@tool
extends Node2D

@export var sprite_frames: SpriteFrames:
	set(value):
		sprite_frames = value
		_actualizar_sprite()

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

var activo := false


func _ready() -> void:
	add_to_group("arbol")
	_actualizar_sprite()


func _actualizar_sprite() -> void:
	if not is_node_ready():
		return

	if animated_sprite_2d == null:
		return

	animated_sprite_2d.sprite_frames = sprite_frames

	if sprite_frames:
		if sprite_frames.has_animation("idle"):
			animated_sprite_2d.play("idle")
		elif sprite_frames.get_animation_names().size() > 0:
			animated_sprite_2d.play(sprite_frames.get_animation_names()[0])
func sacudir() -> void:
	if activo:
		return

	activo = true

	animated_sprite_2d.play("mover")
	print("🌳 El árbol se movió")

	await animated_sprite_2d.animation_finished

	animated_sprite_2d.play("idle")
	activo = false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			var y_scale := randf_range(0.8, 1.2)
			var x_scale := y_scale * randf_range(0.9, 1.1)
			scale = Vector2(x_scale, y_scale)

		NOTIFICATION_EDITOR_PRE_SAVE:
			if animated_sprite_2d:
				animated_sprite_2d.frame_progress = 0


func _on_area_2d_area_entered(area: Area2D) -> void:
	if activo:
		return

	var cuerpo = area.get_parent()

	if cuerpo and cuerpo.is_in_group("enemy"):
		sacudir()
