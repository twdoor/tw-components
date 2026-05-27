@tool
class_name FrameShape extends CollisionShape2D

## Custom collision shape for the frame data system.
## Supports a per-shape HitEffect resource that overrides both the hitbox base
## and the parent FrameData hit effect.

## Frame metadata — set automatically by the frame data system
var frame_index: int = -1
var multi_index: int = -1

@export_group("Hit Properties")
## Optional per-shape hit payload. Leave empty to inherit from the frame/base.
@export var hit_effect_override: HitEffect

@export_group("Frame Tools")
@export_tool_button("Add Hitbox to This Frame") var add_hitbox_to_frame = _add_hitbox
@export_tool_button("Remove This Hitbox") var remove_hitbox = _remove_hitbox
@export_tool_button("Insert Frame Before") var insert_before = _insert_before
@export_tool_button("Insert Frame After") var insert_after = _insert_after


func _ready() -> void:
	debug_color = Color(Color.GREEN, .5)


## Get a display name for this shape
func get_display_name() -> String:
	if multi_index >= 0:
		return "Frame_%d_Multi_%d" % [frame_index, multi_index]
	else:
		return "Frame_%d" % frame_index

## Check if this is part of a multi-hitbox frame
func is_multi_frame() -> bool:
	return multi_index >= 0

## Get the parent FrameDataHitbox2D
func get_frame_data_parent() -> FrameDataHitbox2D:
	var parent = get_parent()
	if parent is FrameDataHitbox2D:
		return parent
	return null

## Tool button implementations
func _add_hitbox():
	var parent = get_frame_data_parent()
	if parent:
		parent.add_hitbox_to_frame(frame_index, position + Vector2(30, 0))

func _remove_hitbox():
	var parent = get_frame_data_parent()
	if parent:
		parent.remove_hitbox_from_frame(frame_index, self)

func _insert_before():
	var parent = get_frame_data_parent()
	if parent:
		parent.insert_frame_before(frame_index)

func _insert_after():
	var parent = get_frame_data_parent()
	if parent:
		parent.insert_frame_after(frame_index)
