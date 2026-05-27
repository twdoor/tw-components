@tool
class_name ColorButton extends Button

const PALETTE_THEME = preload("res://addons/color_palette/palette_theme.tres")

@export var color: Color = Color.WHITE:
	get:
		return color
	set(value):
		color = value
		change_color.call_deferred()

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	change_color()

func change_color():
	self_modulate = color


func _on_focus_entered() -> void:
	pass
	#TODO ADD TWEEN EFFECT HERE

func _on_focus_exited() -> void:
	pass
	#TODO ADD TWEEN EFFECT HERE

func _on_mouse_entered() -> void:
	grab_focus()

func _on_mouse_exited() -> void:
	if has_focus():
		release_focus()
