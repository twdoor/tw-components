class_name Stat extends RefCounted

var base: float
var current: float
var curve: Curve

signal changed(old_value: float, new_value: float)

func _init(base_value: float, scale_curve: Curve = null) -> void:
	base = base_value
	current = base_value
	curve = scale_curve

func recalculate(level_ratio: float, mod_add: float = 0.0, mod_mult: float = 1.0) -> void:
	var old = current

	var scaled = base
	if curve and level_ratio > 0.0:
		scaled *= curve.sample(clampf(level_ratio, 0.0, 0.99))

	current = (scaled + mod_add) * mod_mult

	if old != current:
		changed.emit(old, current)
