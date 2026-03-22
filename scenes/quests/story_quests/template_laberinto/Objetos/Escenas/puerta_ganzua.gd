extends Puerta
class_name Puerta_ganzua

var escena_ya_completada: bool = false

@export var puerta_id: String = ""
@export var next_scene: PackedScene  # 🔥 ahora editable en inspector

func _ready() -> void:
	super()

	# Si esta puerta ya fue forzada, desactiva interacción
	if GameStateLaberinto.puertas_ganzua_forzadas.get(puerta_id, false):
		escena_ya_completada = true
		print("🟢 La puerta %s ya fue forzada. Desactivando interacción." % puerta_id)
		animated_sprite_2d.play("Abierto")
		$CollisionShape2D.disabled = true
		ui_container.visible = false
		set_process(false)

func check_door_status() -> void:
	is_unlocked = true
	show_unlocked_ui()

func show_unlocked_ui() -> void:
	if not escena_ya_completada:
		ui_container.visible = true
		interact_label.text = "Presiona E para forzar la puerta"

func interact() -> void:
	if escena_ya_completada:
		return

	if player_in_range:
		if current_player:
			# ---- GUARDAR ESTADO DEL JUGADOR ----
			GameStateLaberinto.save_player(current_player)

			# Guardar puerta forzada
			GameStateLaberinto.puertas_ganzua_forzadas[puerta_id] = true

			# Guardar cofres abiertos u otros objetos
			GameStateLaberinto.abiertos = current_player.get_cofres_abiertos()

		# ---- ANIMACIÓN DE PUERTA ----
		animated_sprite_2d.play("Abierto")
		$CollisionShape2D.disabled = true
		ui_container.visible = false
		escena_ya_completada = true
		set_process(false)

		# ---- CAMBIAR ESCENA ----
		if next_scene:
			SceneSwitcher2.change_to_packed_with_transition(
				next_scene,
				^"",
				Transition.Effect.FADE,
				Transition.Effect.FADE
			)
		else:
			print("⚠️ No se asignó escena en el inspector")
