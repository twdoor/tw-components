@tool @icon("uid://ctplkvchtuyuv")
class_name Sequence extends Node

signal sequence_finished

enum SequenceOrder {
	FORWARD,
	BACKWARD,
	FULL,
	RANDOM,
}

var index:= 0

@export var run_order: SequenceOrder = SequenceOrder.FULL
@export var player: AnimationPlayer:
	set(v):
		player = v
		# Triggers the editor to call _validate_property
		notify_property_list_changed()
		update_configuration_warnings()

@export var animation_array: Array[StringName]

# Note the underscore: _validate_property is the correct virtual function
func _validate_property(property: Dictionary) -> void:
	if property.name == "animation_array":
		if player:
			var anim_list = player.get_animation_list()
			var options = ",".join(anim_list)


			property.hint = PROPERTY_HINT_TYPE_STRING
			property.hint_string = "%d/%d:%s" % [TYPE_STRING_NAME, PROPERTY_HINT_ENUM, options]
		else:
			property.hint = PROPERTY_HINT_NONE
			property.hint_string = ""


func _get_configuration_warnings() -> PackedStringArray:
	if !player:
		return ["No player added"]
	return []


func play_sequence() -> void:
	if animation_array.is_empty():
		push_error("No animations added")
		return

	if !player:
		push_error("No player added")
		return

	match run_order:
		SequenceOrder.FORWARD:
			await play_forward_sequence()
		SequenceOrder.BACKWARD:
			await play_backward_sequence()
		SequenceOrder.FULL:
			await play_full_sequence()
		SequenceOrder.RANDOM:
			await play_random_sequence()

	sequence_finished.emit()

# Playback functions use 'await player.animation_finished' for timing
func play_forward_sequence() -> void:
	var up_index: int = index % animation_array.size()
	player.play(animation_array[up_index])
	index += 1
	await player.animation_finished

func play_backward_sequence() -> void:
	var size = animation_array.size()
	var down_index: int = (size - (index % size)) - 1
	player.play(animation_array[down_index])
	index += 1
	await player.animation_finished

func play_full_sequence() -> void:
	for animation in animation_array:
		player.play(animation)
		await player.animation_finished

func play_random_sequence() -> void:
	player.play(animation_array.pick_random())
	await player.animation_finished
