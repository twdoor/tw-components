class_name StatMod extends Resource

enum ModType{
	MULTIPLY,
	ADD,
}

@export var stat: Stats.StatTag
@export var amount: float
@export var type: ModType

func _init(
	_stat: Stats.StatTag = Stats.StatTag.MAX_HEALTH,
	_amount: float = 0.0,
	_type: ModType = ModType.ADD
) -> void:
	stat = _stat
	amount = _amount
	type = _type
