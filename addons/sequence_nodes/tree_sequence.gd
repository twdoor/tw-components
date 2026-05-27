@tool @icon("uid://ctplkvchtuyuv")
class_name TreeSequence extends Node

signal sequence_finished

const ROOT_STATE_MACHINE_PATH := "[root]"

enum SequenceOrder {
	FORWARD,
	BACKWARD,
	FULL,
	RANDOM,
}

var index := 0

@export var run_order: SequenceOrder = SequenceOrder.FULL

@export var tree: AnimationTree:
	set(v):
		tree = v
		notify_property_list_changed()
		update_configuration_warnings()

@export var state_machine_path: StringName:
	set(v):
		state_machine_path = v
		notify_property_list_changed()
		update_configuration_warnings()

@export var state_array: Array[StringName]

func _validate_property(property: Dictionary) -> void:
	if property.name == "state_machine_path":
		var paths := _get_state_machine_paths()
		if paths.is_empty():
			property.hint = PROPERTY_HINT_NONE
			property.hint_string = ""
		else:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(paths)

		return

	if property.name != "state_array":
		return

	var states := _get_state_names()

	if states.is_empty():
		property.hint = PROPERTY_HINT_NONE
		property.hint_string = ""
		return

	property.hint = PROPERTY_HINT_TYPE_STRING
	property.hint_string = "%d/%d:%s" % [
		TYPE_STRING_NAME,
		PROPERTY_HINT_ENUM,
		",".join(states)
	]


func _get_configuration_warnings() -> PackedStringArray:
	if !tree:
		return ["No animation tree added"]

	if !_get_state_machine():
		return ["Animation tree needs an AnimationNodeStateMachine root, or a selected state machine path"]

	return []


func play_sequence() -> void:
	if state_array.is_empty():
		push_error("No states added")
		return

	if !tree:
		push_error("No animation tree added")
		return

	tree.active = true

	if !_get_state_machine():
		push_error("No animation state machine found")
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


func play_forward_sequence() -> void:
	var up_index: int = index % state_array.size()
	await play_state(state_array[up_index])
	index += 1


func play_backward_sequence() -> void:
	var size := state_array.size()
	var down_index: int = (size - (index % size)) - 1
	await play_state(state_array[down_index])
	index += 1


func play_full_sequence() -> void:
	for state in state_array:
		await play_state(state)


func play_random_sequence() -> void:
	await play_state(state_array.pick_random())


func play_state(state: StringName) -> void:
	var machine_path := _get_resolved_state_machine_path()
	_travel_to_state_machine(machine_path)

	var playback := _get_playback()
	if !playback:
		push_error("No state machine playback found")
		return

	playback.travel(state)
	await tree.animation_finished


func _travel_to_state_machine(machine_path: String) -> void:
	if machine_path.is_empty():
		return

	var current_path := ""
	for state_name in machine_path.split("/", false):
		var playback_path := "parameters/playback" if current_path.is_empty() else "parameters/%s/playback" % current_path
		var playback := tree.get(playback_path) as AnimationNodeStateMachinePlayback
		if !playback:
			push_error("No parent state machine playback found at %s" % playback_path)
			return

		playback.travel(state_name)
		current_path = state_name if current_path.is_empty() else "%s/%s" % [current_path, state_name]


func _get_playback() -> AnimationNodeStateMachinePlayback:
	if !tree:
		return null

	return tree.get(_get_playback_property_path()) as AnimationNodeStateMachinePlayback


func _get_playback_property_path() -> String:
	var machine_path := _get_resolved_state_machine_path()
	if machine_path.is_empty():
		return "parameters/playback"

	return "parameters/%s/playback" % machine_path


func _get_state_names() -> PackedStringArray:
	var state_machine := _get_state_machine()
	if state_machine:
		return state_machine.get_node_list()

	return []


func _get_state_machine() -> AnimationNodeStateMachine:
	if !tree:
		return null

	var root := tree.tree_root
	if !root:
		return null

	var found := _get_state_machine_entries()
	if !str(state_machine_path).is_empty():
		for entry in found:
			if str(entry["option"]) == str(state_machine_path):
				return entry["machine"] as AnimationNodeStateMachine

	if found.size() == 1:
		return found[0]["machine"] as AnimationNodeStateMachine

	return null


func _get_resolved_state_machine_path() -> String:
	if !tree:
		return ""

	var root := tree.tree_root
	if !root:
		return ""

	var found := _get_state_machine_entries()
	if !str(state_machine_path).is_empty():
		for entry in found:
			if str(entry["option"]) == str(state_machine_path):
				return str(entry["path"])

	if found.size() == 1:
		return str(found[0]["path"])

	return ""


func _get_state_machine_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for entry in _get_state_machine_entries():
		paths.append(str(entry["option"]))

	return paths


func _get_state_machine_entries() -> Array[Dictionary]:
	if !tree or !tree.tree_root:
		return []

	return _find_state_machines(tree.tree_root, "", ROOT_STATE_MACHINE_PATH)


func _find_state_machines(node: AnimationNode, base_path := "", option_path := "") -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if node is AnimationNodeStateMachine:
		found.append({
			"machine": node,
			"path": base_path,
			"option": option_path,
		})

	if node is AnimationNodeBlendTree:
		for child_name in node.get_node_list():
			var child = node.get_node(child_name)
			var child_path: String = str(child_name) if base_path.is_empty() else "%s/%s" % [base_path, child_name]
			found.append_array(_find_state_machines(child, child_path, child_path))

	if node is AnimationNodeStateMachine:
		for child_name in node.get_node_list():
			var child = node.get_node(child_name)
			var child_path: String = str(child_name) if base_path.is_empty() else "%s/%s" % [base_path, child_name]
			found.append_array(_find_state_machines(child, child_path, child_path))

	return found
