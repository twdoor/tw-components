class_name BounceHit extends HitEffect

@export var bounce: bool = false


func _get_hit_normal(obj: Node2D, hurtbox: HitboxComponent2D) -> Vector2:
	var collision_shape := _get_collision_shape(hurtbox)
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rectangle := collision_shape.shape as RectangleShape2D
		var half_size := rectangle.size * 0.5
		var local_hit_position := collision_shape.to_local(obj.global_position)

		var distances := {
			Vector2.LEFT: absf(local_hit_position.x + half_size.x),
			Vector2.RIGHT: absf(half_size.x - local_hit_position.x),
			Vector2.UP: absf(local_hit_position.y + half_size.y),
			Vector2.DOWN: absf(half_size.y - local_hit_position.y),
		}

		var local_normal := Vector2.LEFT
		var smallest_distance := INF
		for candidate_normal in distances:
			var distance := distances[candidate_normal] as float
			if distance < smallest_distance:
				smallest_distance = distance
				local_normal = candidate_normal

		return collision_shape.global_transform.basis_xform(local_normal).normalized()

	return Vector2.ZERO

func _get_collision_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
	return null
