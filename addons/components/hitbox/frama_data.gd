@tool @icon("uid://js7d1lylt15w")
class_name FrameData extends Resource

## Data structure to represent a single frame in the attack sequence.
## Supports a per-frame HitEffect resource that overrides the hitbox base.

enum FrameType {
	SINGLE,
	MULTI,
	EMPTY
}

@export var frame_type: FrameType = FrameType.SINGLE
@export var frame_index: int = 0
@export var shape_indices: Array[int] = []

## Optional per-frame hit payload. Leave empty to inherit the hitbox's effect.
@export var hit_effect_override: HitEffect

func _init(type: FrameType = FrameType.SINGLE, index: int = 0):
	frame_type = type
	frame_index = index
	shape_indices = []

## Add a shape index to this frame
func add_shape_index(index: int):
	if not shape_indices.has(index):
		shape_indices.append(index)

## Remove a shape index from this frame
func remove_shape_index(index: int):
	shape_indices.erase(index)

## Get the number of hitboxes in this frame
func get_hitbox_count() -> int:
	return shape_indices.size()

## Check if this is an empty frame
func is_empty() -> bool:
	return frame_type == FrameType.EMPTY or shape_indices.is_empty()
