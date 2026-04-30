extends Node2D
@export var poison_area_scene: PackedScene
var poison_preview: Node2D = null
var selecting_poison := false

func _physics_process(delta: float) -> void:

# Activar selección de área de veneno
	# Activar selección de área de veneno
	if Input.is_action_just_pressed("area_veneno") and not selecting_poison:
		selecting_poison = true
		poison_preview = Node2D.new()

		# 🔹 Sprite como círculo celeste transparente
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://assets/third_party/inputs/keyboard-and-mouse/Blanks/Blank_White_Enter.png") 
		sprite.modulate = Color(0.3, 0.8, 1.0, 0.4)  # celeste con alpha
		sprite.scale = Vector2(1.5, 1.5) # tamaño del área
		sprite.centered = true
		poison_preview.add_child(sprite)

		get_tree().current_scene.add_child(poison_preview)
		print("[VENENO] Selección iniciada: mostrando círculo de preview")

	if selecting_poison and poison_preview:
		poison_preview.global_position = get_global_mouse_position()

		# Colocar veneno con click izquierdo
		if Input.is_action_just_pressed("veneno_activo"): 
			var poison_instance = poison_area_scene.instantiate()
			get_tree().current_scene.add_child(poison_instance)
			poison_instance.global_position = poison_preview.global_position
			print("[VENENO] ¡Área de veneno colocada en: ", poison_instance.global_position, "!")
			poison_preview.queue_free()
			poison_preview = null
			selecting_poison = false
