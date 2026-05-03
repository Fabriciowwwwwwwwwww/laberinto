extends Area2D

@export var damage_per_tick: float = 5.0   # ahora hace 5 de daño
@export var tick_time: float = 0.5
@export var duration: float = 5.0

@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var damage_timer: Timer = $"../DamageTimer"
@onready var life_timer: Timer = $"../LifeTimer"

func _ready() -> void:
	if sprite:
		sprite.play("idle")

	if damage_timer:
		damage_timer.wait_time = tick_time
		damage_timer.start()
		damage_timer.timeout.connect(_on_DamageTimer_timeout)
		print("[VENENO] DamageTimer iniciado con ", tick_time, "s")

	if life_timer:
		life_timer.wait_time = duration
		life_timer.start()
		life_timer.timeout.connect(_on_LifeTimer_timeout)
		print("[VENENO] LifeTimer iniciado con ", duration, "s")


func _on_DamageTimer_timeout() -> void:
	var bodies = get_overlapping_bodies()
	print("[VENENO] Tick de daño, cuerpos detectados: ", bodies.size())

	for obj in bodies:
		if obj.is_in_group("enemigos"):
			if obj.has_method("recibir_daño"):
				obj.recibir_daño(damage_per_tick)  # ← aquí estaba el error


func _on_LifeTimer_timeout() -> void:
	print("[VENENO] Se terminó la duración, eliminando área...")
	if sprite:
		sprite.queue_free()
	queue_free()
