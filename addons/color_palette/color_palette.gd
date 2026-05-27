class_name ColorPaletteMaker extends GridContainer

const COLOR_BUTTON = preload("res://addons/color_palette/color_button/color_button.tscn")

@export var colors: Array[Color]

var picked_color: Color
var is_request_active: bool = false
var request_callback: Callable


func setup_palette():
	for color in colors:
		var new_button = COLOR_BUTTON.instantiate() as ColorButton
		new_button.color = color
		new_button.pressed.connect(_on_color_pressed.bind(new_button))
		add_child(new_button)


func _on_color_pressed(color_button: ColorButton) -> void:
	picked_color = color_button.color
	if is_request_active:
		if request_callback.is_valid():
			request_callback.call(color_button.color)
		
		is_request_active = false
		request_callback = Callable()
		


func request_color(callback: Callable) -> void:
	is_request_active = true
	request_callback = callback
	print("Color requested!!")


func cancel_request() -> void:
	if is_request_active:
		is_request_active = false
		request_callback = Callable()
		print("Color request cancelled")
