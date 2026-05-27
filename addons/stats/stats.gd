@tool
class_name Stats extends Resource

#region Stats
enum StatTag {
	MAX_HEALTH,
}

var _stat_map: Dictionary[StatTag, Stat] = {}
var stat_mods: Array[StatMod]

@export var base_max_health: float = 10

var max_health: Stat

var current_health: float:
	set(value):
		current_health = clamp(value, 0, max_health.current)
		health_changed.emit(current_health, max_health.current)
		if current_health <= 0:
			health_depleated.emit()
signal health_changed(current_value: float, max_value: float)
signal health_depleated

@export var current_level: int = 1:
	set(value):
		var old_level = current_level
		current_level = clampi(value, 1, max_level)
		if old_level != current_level:
			recalculate_stats.call_deferred()

@export var max_level: int = 30

@export_group("Stat Curves")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var stat_curves_enabled:= false
@export var stat_curves: Dictionary[StatTag, Curve]

#endregion


func setup_stats() -> void:
	max_health = create_stat(StatTag.MAX_HEALTH, base_max_health)
	
	
	recalculate_stats()
	current_health = max_health.current
	

func add_mod(mod: StatMod) -> void:
	stat_mods.append(mod)
	recalculate_stats.call_deferred()

func remove_mod(mod: StatMod) -> void:
	if !stat_mods.has(mod): return
	stat_mods.erase(mod)
	recalculate_stats.call_deferred()

func recalculate_stats():
	var level_ratio := float(current_level - 1) / (max_level - 1)
	
	var add_totals: Dictionary = {}
	var mult_totals: Dictionary = {}
	
	for mod in stat_mods:
		match mod.type:
			StatMod.ModType.ADD:
				if not add_totals.has(mod.stat):
					add_totals[mod.stat] = 0.0
				add_totals[mod.stat] += mod.amount
			StatMod.ModType.MULTIPLY:
				if not mult_totals.has(mod.stat):
					mult_totals[mod.stat] = 1.0
				mult_totals[mod.stat] += mod.amount
	
	for stat_enum in _stat_map:
		var stat: Stat = _stat_map[stat_enum]
		var add := add_totals.get(stat_enum, 0.0)
		var mult := mult_totals.get(stat_enum, 1.0)
		stat.recalculate(level_ratio, add, mult)


func create_stat(tag: StatTag, base: float) -> Stat:
	var curve: Curve = stat_curves.get(tag)
	var stat := Stat.new(base, curve)
	_stat_map[tag] = stat
	return stat
		
