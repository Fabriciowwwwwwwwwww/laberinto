extends Chest
class_name Vida

# =====================================================
# READY
# =====================================================
func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	ui_container.visible = false
	progress_bar.min_value = 0
	progress_bar.max_value = interaction_time
	progress_bar.value = 0
	
	# 🔥 Animación inicial
	if not is_opened:
		animated_sprite_2d.play("idle")
	else:
		queue_free()


# =====================================================
# PROCESS
# =====================================================
func _process(delta: float) -> void:
	if is_interacting and player_in_range and not is_opened:
		interaction_progress += delta
		progress_bar.value = interaction_progress
		
		if interaction_progress >= interaction_time:
			open_chest()


# =====================================================
# DETECCIÓN DE JUGADOR
# =====================================================
func _on_body_entered(body: Node) -> void:
	if body is Player_l and not is_opened:
		player_in_range = true
		current_player = body
		body.set_current_chest(self)
		show_ui()


func _on_body_exited(body: Node) -> void:
	if body is Player_l:
		player_exit()


func player_exit() -> void:
	player_in_range = false
	
	if current_player:
		current_player.clear_current_chest()
		current_player = null
	
	stop_interaction()
	hide_ui()


# =====================================================
# INTERACCIÓN
# =====================================================
func start_interaction() -> void:
	if not is_opened and player_in_range:
		is_interacting = true
		interact_label.text = "Absorbiendo esencia..."
		
		# 🔥 animación mientras mantiene E
		if animated_sprite_2d.animation != "cargando":
			animated_sprite_2d.play("cargando")
		
		if not audio_open.playing:
			audio_open.play()


func stop_interaction() -> void:
	is_interacting = false
	interaction_progress = 0.0
	progress_bar.value = 0
	
	if audio_open.playing:
		audio_open.stop()
	
	# 🔥 volver a idle si cancela
	if not is_opened:
		animated_sprite_2d.play("idle")
		interact_label.text = "Mantén E para absorber"


# =====================================================
# FUNCIÓN PRINCIPAL (AL TERMINAR)
# =====================================================
func open_chest() -> void:
	is_opened = true
	is_interacting = false
	interaction_progress = 0.0
	
	print("¡Objeto de vida usado!")
	
	# ❤️ CURAR
	if current_player:
		current_player.sumar_vida(30)
	
	# 🔇 detener sonido
	if audio_open.playing:
		audio_open.stop()
	
	# 🎬 animación (puede estar en loop)
	animated_sprite_2d.play("cargando")
	
	# 🔒 MARCAR COMO USADO en GameState
	GameStateLaberinto.mark_objeto_destruido(get_path())
	
	chest_opened.emit()
	hide_ui()
	
	# ⏳ pequeño delay visual (opcional)
	await get_tree().create_timer(0.2).timeout
	
	# 💥 destruir
	queue_free()

# =====================================================
# UI
# =====================================================
func show_ui() -> void:
	ui_container.visible = true
	interact_label.text = "Mantén E para absorber"


func hide_ui() -> void:
	ui_container.visible = false


# =====================================================
# CARGA DESDE SAVE
# =====================================================
func abrir_sin_interaccion() -> void:
	is_opened = true
	queue_free()
