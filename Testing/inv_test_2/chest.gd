extends Button

signal toggle_inventory(external_owner)

@export var inventory_data: InventoryData


func _ready() -> void:
	pressed.connect(on_player_interact)

func on_player_interact():
	toggle_inventory.emit(self)
