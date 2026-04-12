extends Node2D

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://d36eq8tqdaxdy")

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

var activo := false


func _ready() -> void:
	add_to_group("arbol") # Grupo de árboles
	_set_sprite_frames(sprite_frames)

	var frames_length: int = animated_sprite_2d.sprite_frames.get_frame_count(
		animated_sprite_2d.animation
	)

	animated_sprite_2d.frame = randi_range(0, frames_length)


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames

	if not is_node_ready():
		return

	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME

	animated_sprite_2d.sprite_frames = new_sprite_frames
	animated_sprite_2d.play(animated_sprite_2d.animation)


func sacudir():
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
			animated_sprite_2d.frame_progress = 0


# 🔥 DETECCIÓN DEL ENEMIGO
func _on_area_2d_area_entered(area: Area2D) -> void:
	if activo:
		return

	var cuerpo = area.get_parent()

	if cuerpo and cuerpo.is_in_group("enemy"):
		sacudir()
