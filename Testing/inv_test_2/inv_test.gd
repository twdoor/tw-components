extends Control

@export var inventory_data: InventoryData
@export var main_inventory: Inventory
@onready var grabbed_slot: InventorySlot = $GrabbedSlot

@export var chest_data: InventoryData
@export var chest_inventory: Inventory

var grab_slot_data: SlotData

func _ready() -> void:
	setup_inventory(inventory_data, main_inventory)
	setup_inventory(chest_data, chest_inventory)

func _process(_delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5,5)


func setup_inventory(data: InventoryData, node: Inventory):
	node.set_inventory_data(data)
	data.inventory_interact.connect(_on_inventory_interact)


func _on_inventory_interact(_inventory_data: InventoryData, index: int, action: InventorySlot.InputType) -> void:
	match [grab_slot_data, action]:
		[null, InventorySlot.InputType.MOVE]:
			grab_slot_data = inventory_data.grab_slot_data(index)
		[_, InventorySlot.InputType.MOVE]:
			grab_slot_data = inventory_data.drop_slot_data(grab_slot_data, index)
		[null, InventorySlot.InputType.USE]:
			pass
		[_, InventorySlot.InputType.USE]:
			grab_slot_data = inventory_data.drop_single_slot_data(grab_slot_data, index)
	
	update_grabbed_slot()

func update_grabbed_slot() -> void:
	if grab_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grab_slot_data)
	else: grabbed_slot.hide()
