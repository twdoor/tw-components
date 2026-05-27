extends Sprite2D

@export var hitbox: HitboxComponent2D

var speed: float = 400

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	if hitbox:
		hitbox.hit_hurtbox.connect(_on_hurtbox_hit)

func _process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return

	position += direction * speed * delta

func _on_hurtbox_hit(hurtbox: HitboxComponent2D, hit_effect: HitEffect) -> void:
	if hit_effect is BounceHit:
		if hit_effect.bounce:
			var normal : Vector2 = hit_effect._get_hit_normal(self, hurtbox)
			direction = direction.bounce(normal).normalized()
