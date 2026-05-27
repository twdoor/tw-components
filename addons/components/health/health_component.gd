@icon("uid://43wqhdccs2f5")
class_name HealthComponent extends Node

signal health_changed(old_value: float, new_value: float)
signal health_decreased(by_value: float)
signal health_increased(by_value: float)
signal health_depleated()
signal max_health_changed(old_value: float, new_value: float)

var health: float = 1:
	set = set_health

var max_health: float = 1:
	set = set_max_health


func set_health(new_val: float):
	var old_val = health
	health = clamp(new_val, 0, max_health)
	health_changed.emit(old_val, new_val)
	
	var dif = old_val - new_val
	if dif > 0: health_decreased.emit(dif)
	else: health_increased.emit(dif)
	
	if health <= 0:
		health_depleated.emit()


func set_max_health(new_val: float):
	var old_val = max_health
	max_health = max(0, new_val)
	max_health_changed.emit(old_val, new_val)


func setup_component(max_health_value: float = 1):
	set_max_health(max_health_value)
	health = max_health
