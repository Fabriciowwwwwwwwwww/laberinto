extends CollisionShape2D
func _on_area_body_entered(body):

	if body.is_in_group("player"):

		$SpawnerSabuesos.reactivar_spawn()
