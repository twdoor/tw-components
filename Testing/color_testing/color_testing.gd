extends Node

@onready var color_palette_maker: ColorPaletteMaker = $ColorPaletteMaker
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	color_palette_maker.setup_palette()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test1"):
		color_palette_maker.request_color(_on_color_received)

func _on_color_received(color: Color) -> void:
	sprite_2d.self_modulate = color
