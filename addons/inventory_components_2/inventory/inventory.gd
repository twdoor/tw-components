class_name Inventory extends PanelContainer

const SLOT = preload("uid://dsjwusyjqiaox")

@onready var item_grid: GridContainer = %ItemGrid

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.invetory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)

func populate_item_grid(inventory_data: InventoryData) -> void:
	if item_grid.get_child_count() != inventory_data.slot_datas.size():
		for child in item_grid.get_children():
			child.queue_free()
		
		for i in inventory_data.slot_datas.size():
			var slot: InventorySlot = SLOT.instantiate()
			item_grid.add_child(slot)
			slot.slot_clicked.connect(inventory_data.on_slot_clicked)
	
	for i in inventory_data.slot_datas.size():
		var slot: InventorySlot = item_grid.get_child(i)
		var slot_data = inventory_data.slot_datas[i]
		
		if slot_data:
			slot.set_slot_data(slot_data)
		else:
			slot.clear_slot()
