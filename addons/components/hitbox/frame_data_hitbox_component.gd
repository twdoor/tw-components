@tool
class_name FrameDataHitbox2D extends HitboxComponent2D

## Frame-based hitbox system for fighting games and animated attacks.
## Supports single, multi-hitbox, and empty frames with easy frame navigation.
##
## HitEffect resolution order:
##   First active FrameShape.hit_effect_override
##   → current FrameData.hit_effect_override
##   → HitboxComponent2D.hit_effect

@export_tool_button("Add Single Frame") var add_single_frame = _add_single_frame
@export_tool_button("Add Multi-Frame (2 Hitboxes)") var add_multi_2 = _add_multi_frame_2
@export_tool_button("Add Multi-Frame (3 Hitboxes)") var add_multi_3 = _add_multi_frame_3
@export_tool_button("Add Empty Frame") var add_empty_frame = _add_empty_frame
@export_tool_button("Remove Last Frame") var remove_last_frame = _remove_last_frame
@export_tool_button("Clear All Frames") var clear_frames = _clear_all_frames


@export_group("Frame Navigation")
@export var current_frame: int = 0:
	set(value):
		current_frame = clampi(value, 0, get_frame_count() - 1)
		_update_active_frame()

@export_group("Frame Data")
## Internal array tracking all frames in order
@export var frame_data_array: Array[FrameData] = []


func _ready():
	super._ready()

	if not Engine.is_editor_hint():
		current_frame = 0
		_update_active_frame()
		disable_all()


#region Hit effect resolution


func _get_hitbox_node_name() -> String:
	return "HitFrame"


func _get_hurtbox_node_name() -> String:
	return "HurtFrame"


## Compatibility helper for code that only needs damage.
func get_hit_damage() -> float:
	return get_hit_effect().damage


## Returns the resolved hit effect for the current frame.
## Shape overrides replace frame/base effects. Frame overrides replace base.
func get_hit_effect() -> HitEffect:
	for shape in get_current_active_shapes():
		if shape.hit_effect_override:
			return shape.hit_effect_override.duplicate_for_hit()

	var frame_data := get_current_frame_data()
	if frame_data and frame_data.hit_effect_override:
		return frame_data.hit_effect_override.duplicate_for_hit()

	return super.get_hit_effect()

#endregion

#region Frame queries


## Get the total number of frames
func get_frame_count() -> int:
	return frame_data_array.size()

## Get all FrameShape children
func get_all_shapes() -> Array[FrameShape]:
	var shapes: Array[FrameShape] = []
	for child in get_children():
		if child is FrameShape:
			shapes.append(child)
	return shapes

## Advance to the next frame (wraps around)
func next_frame():
	if get_frame_count() == 0:
		return
	current_frame = (current_frame + 1) % get_frame_count()

## Go to the previous frame (wraps around)
func previous_frame():
	if get_frame_count() == 0:
		return
	current_frame = (current_frame - 1) if current_frame > 0 else (get_frame_count() - 1)

## Go to a specific frame by index
func set_frame(frame_index: int):
	current_frame = frame_index

## Reset to frame 0
func reset_frames():
	current_frame = 0

## Disable all hitboxes
func disable_all():
	for shape in get_all_shapes():
		shape.disabled = true
	disable_collisions = true

## Enable collision processing (used when activating hitbox)
func enable():
	super.enable()
	_update_active_frame()

## Get the FrameData for the current frame
func get_current_frame_data() -> FrameData:
	if current_frame >= 0 and current_frame < frame_data_array.size():
		return frame_data_array[current_frame]
	return null

## Get all active shapes for the current frame
func get_current_active_shapes() -> Array[FrameShape]:
	var active_shapes: Array[FrameShape] = []
	var frame_data = get_current_frame_data()
	if frame_data:
		var all_shapes = get_all_shapes()
		for shape_idx in frame_data.shape_indices:
			if shape_idx < all_shapes.size():
				active_shapes.append(all_shapes[shape_idx])
	return active_shapes

#endregion

#region Internal frame activation

## Internal: Update which frame's collision shapes are active
func _update_active_frame():
	var all_shapes = get_all_shapes()

	for shape in all_shapes:
		shape.disabled = true

	if current_frame >= 0 and current_frame < frame_data_array.size():
		var frame_data = frame_data_array[current_frame]
		for shape_idx in frame_data.shape_indices:
			if shape_idx < all_shapes.size():
				all_shapes[shape_idx].disabled = false

#endregion

#region Frame creation helpers

## Internal: Create a FrameShape with default settings
func _create_frame_shape(frame_idx: int, multi_idx: int = -1, offset: Vector2 = Vector2.ZERO) -> FrameShape:
	var frame_shape = FrameShape.new()

	frame_shape.position = offset
	frame_shape.frame_index = frame_idx
	frame_shape.multi_index = multi_idx

	if multi_idx >= 0:
		frame_shape.name = "Frame_%d_Multi_%d" % [frame_idx, multi_idx]
	else:
		frame_shape.name = "Frame_%d" % frame_idx

	add_child(frame_shape)
	frame_shape.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else owner

	return frame_shape

## Internal: Get the index of a shape in the children array
func _get_shape_index(shape: FrameShape) -> int:
	var shapes = get_all_shapes()
	return shapes.find(shape)

## Tool button implementations
func _add_single_frame():
	var frame_idx = get_frame_count()
	var frame_data = FrameData.new(FrameData.FrameType.SINGLE, frame_idx)

	var shape = _create_frame_shape(frame_idx)
	var shape_idx = _get_shape_index(shape)
	frame_data.add_shape_index(shape_idx)

	frame_data_array.append(frame_data)
	print("Added single frame %d" % frame_idx)

func _add_multi_frame_2():
	_add_multi_frame(2)

func _add_multi_frame_3():
	_add_multi_frame(3)

func _add_multi_frame(hitbox_count: int):
	var frame_idx = get_frame_count()
	var frame_data = FrameData.new(FrameData.FrameType.MULTI, frame_idx)

	var offsets = []
	match hitbox_count:
		2:
			offsets = [Vector2(-20, 0), Vector2(20, 0)]
		3:
			offsets = [Vector2(-30, 0), Vector2(0, 0), Vector2(30, 0)]
		_:
			for i in hitbox_count:
				offsets.append(Vector2(i * 20 - (hitbox_count - 1) * 10, 0))

	for i in hitbox_count:
		var shape = _create_frame_shape(frame_idx, i, offsets[i])
		var shape_idx = _get_shape_index(shape)
		frame_data.add_shape_index(shape_idx)

	frame_data_array.append(frame_data)
	print("Added multi-frame %d with %d hitboxes" % [frame_idx, hitbox_count])

func _add_empty_frame():
	var frame_idx = get_frame_count()
	var frame_data = FrameData.new(FrameData.FrameType.EMPTY, frame_idx)

	frame_data_array.append(frame_data)
	print("Added empty frame %d (no hitbox)" % frame_idx)

func _remove_last_frame():
	if frame_data_array.is_empty():
		print("No frames to remove")
		return

	var last_frame = frame_data_array[frame_data_array.size() - 1]
	var all_shapes = get_all_shapes()

	for shape_idx in last_frame.shape_indices:
		if shape_idx < all_shapes.size():
			all_shapes[shape_idx].queue_free()

	frame_data_array.remove_at(frame_data_array.size() - 1)
	current_frame = clampi(current_frame, 0, get_frame_count() - 1)
	print("Removed last frame")

func _clear_all_frames():
	for shape in get_all_shapes():
		shape.queue_free()

	frame_data_array.clear()
	current_frame = 0
	print("Cleared all frames")

#endregion

#region Advanced frame manipulation

## Advanced: Add a hitbox to an existing frame (convert single to multi)
func add_hitbox_to_frame(frame_idx: int, offset: Vector2 = Vector2.ZERO):
	if frame_idx < 0 or frame_idx >= frame_data_array.size():
		print("Invalid frame index")
		return

	var frame_data = frame_data_array[frame_idx]

	if frame_data.frame_type == FrameData.FrameType.SINGLE:
		frame_data.frame_type = FrameData.FrameType.MULTI

	if frame_data.frame_type == FrameData.FrameType.EMPTY:
		print("Cannot add hitbox to empty frame")
		return

	var multi_idx = frame_data.get_hitbox_count()
	var shape = _create_frame_shape(frame_idx, multi_idx, offset)
	var shape_idx = _get_shape_index(shape)
	frame_data.add_shape_index(shape_idx)

	print("Added hitbox to frame %d (now has %d hitboxes)" % [frame_idx, frame_data.get_hitbox_count()])

## Advanced: Remove a specific hitbox from a frame
func remove_hitbox_from_frame(frame_idx: int, shape: FrameShape):
	if frame_idx < 0 or frame_idx >= frame_data_array.size():
		print("Invalid frame index")
		return

	var frame_data = frame_data_array[frame_idx]
	var shape_idx = _get_shape_index(shape)

	if frame_data.get_hitbox_count() == 1:
		shape.queue_free()
		frame_data_array.remove_at(frame_idx)
		_reindex_frames()
		print("Removed frame %d (was last hitbox)" % frame_idx)
	else:
		shape.queue_free()
		frame_data.remove_shape_index(shape_idx)
		print("Removed hitbox from frame %d" % frame_idx)

## Advanced: Insert a new single frame before the specified index
func insert_frame_before(frame_idx: int):
	if frame_idx < 0 or frame_idx >= frame_data_array.size():
		print("Invalid frame index")
		return

	var new_frame_data = FrameData.new(FrameData.FrameType.SINGLE, frame_idx)
	var shape = _create_frame_shape(frame_idx)
	var shape_idx = _get_shape_index(shape)
	new_frame_data.add_shape_index(shape_idx)

	frame_data_array.insert(frame_idx, new_frame_data)
	_reindex_frames()
	print("Inserted new frame before frame %d" % frame_idx)

## Advanced: Insert a new single frame after the specified index
func insert_frame_after(frame_idx: int):
	if frame_idx < 0 or frame_idx >= frame_data_array.size():
		print("Invalid frame index")
		return

	var new_idx = frame_idx + 1
	var new_frame_data = FrameData.new(FrameData.FrameType.SINGLE, new_idx)
	var shape = _create_frame_shape(new_idx)
	var shape_idx = _get_shape_index(shape)
	new_frame_data.add_shape_index(shape_idx)

	frame_data_array.insert(new_idx, new_frame_data)
	_reindex_frames()
	print("Inserted new frame after frame %d" % frame_idx)

## Internal: Reindex all frames and shapes after insertion/removal
func _reindex_frames():
	var all_shapes = get_all_shapes()

	for i in range(frame_data_array.size()):
		var frame_data = frame_data_array[i]
		frame_data.frame_index = i

		var multi_counter = 0
		for shape_idx in frame_data.shape_indices:
			if shape_idx < all_shapes.size():
				var shape = all_shapes[shape_idx]
				shape.frame_index = i

				if frame_data.frame_type == FrameData.FrameType.MULTI:
					shape.multi_index = multi_counter
					shape.name = "Frame_%d_Multi_%d" % [i, multi_counter]
					multi_counter += 1
				else:
					shape.multi_index = -1
					shape.name = "Frame_%d" % i

#endregion
