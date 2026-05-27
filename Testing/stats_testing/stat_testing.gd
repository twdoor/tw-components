extends Node2D

@export var stats: Stats

var buff:= StatMod.new(Stats.StatTag.MAX_HEALTH, 15, StatMod.ModType.ADD)

func _ready() -> void:
	stats.setup_stats()
	
	stats.max_health.changed.connect(_on_changed)
	
func _on_changed(_old: float, new: float):
	print(new)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test1"):
		stats.add_mod(buff)
		get_tree().create_timer(5).timeout.connect(func(): stats.remove_mod(buff))
