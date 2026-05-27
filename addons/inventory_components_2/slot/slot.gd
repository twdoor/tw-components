class_name InventorySlot extends Button

enum InputType {
	MOVE,
	USE,
	INSPECT,
}

var interaction_dic: Dictionary[InputType, StringName] = {
	InputType.MOVE: "",
	InputType.USE: "test1",
	InputType.INSPECT: "test2",
}


signal  slot_clicked(index: int, action: InputType)

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity_label: Label = %QuantityLabel

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_slot_data(slot_data: SlotData) -> void:
	var item_data = slot_data.item_data
	item_texture.texture = item_data.texture
	tooltip_text = "%s\n%s" %[item_data.name, item_data.description]
	
	if slot_data.quantity > 1:
		quantity_label.text = "%s" %slot_data.quantity
		quantity_label.show()
	else: quantity_label.hide()


func clear_slot() -> void:
	item_texture.texture = null
	quantity_label.hide()
	tooltip_text = ""



#func _on_gui_input(event: InputEvent) -> void:
	#
	#for interaction_type in interaction_dic:
		#if event.is_action_pressed(interaction_dic[interaction_type]):
			#slot_clicked.emit(get_index(), interaction_type)
			#break


func _on_pressed() -> void:
	if Input.is_action_pressed(interaction_dic[InputType.USE]):
		slot_clicked.emit(get_index(), InputType.USE)
	else:
		slot_clicked.emit(get_index(), InputType.MOVE)


func _on_mouse_entered() -> void:
	grab_focus()

func _on_mouse_exited() -> void:
	release_focus()
