extends CharacterBody2D

@export var hurtbox: HitboxComponent2D

@export var bullet_scene: PackedScene

var speed: float = 200
var direction: Vector2 = Vector2.ZERO

var health: int = 10:
	set(value):
		health = value
		print("health set to ", health)

var drag_coef = -25

func _ready() -> void:
	if hurtbox:
		hurtbox.hit_by_hitbox.connect(_on_hurtbox_hit)
		print("hurtbox hit_by_hitbox connected")

func _process(delta: float) -> void:
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = lerp(velocity, direction * speed, 1 - exp(drag_coef * delta))
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		var bullet = bullet_scene.instantiate()
		add_sibling(bullet)
		bullet.global_position = global_position
		bullet.direction = global_position.direction_to(get_global_mouse_position())


func _on_hurtbox_hit(_hitbox: HitboxComponent2D, hit_effect: HitEffect) -> void:
	health -= int(hit_effect.damage)
