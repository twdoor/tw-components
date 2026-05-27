@icon("uid://bwtkkk6iliue7")
class_name InventoryData extends Resource

signal invetory_updated(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, action: InventorySlot.InputType)

@export var name: StringName
@export var slot_datas: Array[SlotData]

func on_slot_clicked(index: int, action: InventorySlot.InputType) -> void:
	inventory_interact.emit(self, index, action)

func grab_slot_data(index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		invetory_updated.emit(self)
		return slot_data
	else: return null
	
func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	var return_slot_data: SlotData
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	else:
		slot_datas[index] = grabbed_slot_data
		return_slot_data = slot_data
		
	invetory_updated.emit(self)
	return return_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if !slot_data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data())
		
	invetory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null
