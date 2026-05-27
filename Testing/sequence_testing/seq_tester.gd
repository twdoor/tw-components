extends Node

signal enter_second

@onready var attack_button: Button = $AttackButton

@export var first_phase: TreeSequence
@export var sec_phase: TreeSequence
@export var max_health: int = 10
var health: int:
	set(value):
		health = value
		if health <= max_health / 2.0:
			enter_second.emit()

var curent_seq: TreeSequence:
	set(v):
		curent_seq = v

func _ready() -> void:
	health = max_health
	curent_seq = first_phase

	attack_button.pressed.connect(_on_attack_pressed)
	enter_second.connect(_on_enter_second)


func _on_attack_pressed() -> void:
	attack_button.disabled = true
	await curent_seq.play_sequence()
	health -= 1
	attack_button.disabled = false

func _on_enter_second() -> void:
	curent_seq = sec_phase
