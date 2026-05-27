@icon("uid://bcgi51kyxd1rr")
class_name SlotData extends Resource

@export var item_data: ItemData
@export var quantity: int = 1

func can_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data and quantity < item_data.max_stack

func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data and quantity + other_slot_data.quantity <= item_data.max_stack

func fully_merge_with(other_slot_data: SlotData) -> void:
	quantity += other_slot_data.quantity

func create_single_slot_data() -> SlotData:
	var new_slot_data: SlotData = duplicate()
	new_slot_data.quantity = 1
	quantity -= 1
	return new_slot_data
