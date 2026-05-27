class_name HierarchicalStateMachine

signal state_changed(state: String)
signal state_pushed(state: String, stack_size: int)
signal state_popped(from_state: String, to_state: String, stack_size: int)
signal stack_cleared()
signal substate_changed(parent_state: String, substate: String)

var state_dictionary = {}
var current_state: String:
	set(value):
		current_state = value
		state_changed.emit(value)

# Pushdown Automata Stack
var state_stack: Array[Dictionary] = []
var max_stack_size: int = -1

# Hierarchical State Machine Support
var substates: Dictionary = {}  # Maps parent states to child state machines
var active_substates: Dictionary = {}  # Current active substate for each parent


func add_states(
	normal_state_callable: Callable,
	enter_state_callable: Callable = Callable(),
	leave_state_callable: Callable = Callable()
) -> void:
	state_dictionary[normal_state_callable.get_method()] = {
		"normal": normal_state_callable,
		"enter": enter_state_callable,
		"leave": leave_state_callable
	}


func set_initial_state(state_callable: Callable) -> void:
	var state_name = state_callable.get_method()
	if state_dictionary.has(state_name):
		_set_state(state_name)
	else:
		push_warning("No state with name " + state_name)


func update() -> void:
	if current_state != null:
		# Update parent state
		(state_dictionary[current_state].normal as Callable).call()
		
		# Update active substate if it exists
		if substates.has(current_state):
			var substate_machine = substates[current_state]
			substate_machine.update()


func change_state(state_callable: Callable) -> void:
	var state_name = state_callable.get_method()
	if state_dictionary.has(state_name):
		_set_state.call_deferred(state_name)
	else:
		push_warning("No state with name " + state_name)


# =============================================================================
# HIERARCHICAL STATE MACHINE METHODS
# =============================================================================

## Add a child state machine to a parent state
## The child FSM will be automatically updated when the parent state is active
func add_substate_machine(parent_state_callable: Callable, child_fsm: HierarchicalStateMachine) -> void:
	var parent_name = parent_state_callable.get_method()
	
	if !state_dictionary.has(parent_name):
		push_warning("Parent state '%s' doesn't exist" % parent_name)
		return
	
	substates[parent_name] = child_fsm
	
	# Connect to child's state changes
	if !child_fsm.state_changed.is_connected(_on_substate_changed):
		child_fsm.state_changed.connect(_on_substate_changed.bind(parent_name))


## Get the child state machine for a parent state
func get_substate_machine(parent_state_callable: Callable) -> HierarchicalStateMachine:
	var parent_name = parent_state_callable.get_method()
	return substates.get(parent_name, null)


## Check if a state has a child state machine
func has_substate_machine(parent_state_callable: Callable) -> bool:
	var parent_name = parent_state_callable.get_method()
	return substates.has(parent_name)


## Get the current substate name for a parent state
func get_current_substate(parent_state_callable: Callable) -> String:
	var parent_name = parent_state_callable.get_method()
	if substates.has(parent_name):
		return substates[parent_name].current_state
	return ""


## Change the substate within the current parent state
func change_substate(substate_callable: Callable) -> void:
	if substates.has(current_state):
		substates[current_state].change_state(substate_callable)
	else:
		push_warning("Current state '%s' has no substates" % current_state)


## Get full state path (e.g., "water/swimming" or "ground/running")
func get_full_state_path(separator: String = "/") -> String:
	var path = current_state
	if substates.has(current_state):
		var substate = substates[current_state].current_state
		if substate:
			path += separator + substate
			# Recursive: check if substate also has substates
			var child_fsm = substates[current_state]
			if child_fsm.substates.has(substate):
				path += separator + child_fsm.get_full_state_path(separator)
	return path


## Get all active states in the hierarchy as an array
func get_state_hierarchy() -> Array[String]:
	var hierarchy: Array[String] = [current_state]
	
	if substates.has(current_state):
		var child_fsm = substates[current_state]
		if child_fsm.current_state:
			hierarchy.append_array(child_fsm.get_state_hierarchy())
	
	return hierarchy


## Check if we're in a specific state at any level of the hierarchy
func is_in_state_hierarchy(state_callable: Callable) -> bool:
	var state_name = state_callable.get_method()
	var hierarchy = get_state_hierarchy()
	return state_name in hierarchy


# =============================================================================
# PUSHDOWN AUTOMATA METHODS
# =============================================================================

func push_state(state_callable: Callable, context_data: Dictionary = {}) -> void:
	var state_name = state_callable.get_method()
	if !state_dictionary.has(state_name):
		push_warning("No state with name " + state_name)
		return
	
	if max_stack_size > 0 and state_stack.size() >= max_stack_size:
		push_warning("Stack size limit reached (%d)" % max_stack_size)
		return
	
	# Save current state and its active substate
	if current_state:
		var saved_context = context_data.duplicate()
		saved_context["_substate"] = get_current_substate_name()
		
		state_stack.push_back({
			"state": current_state,
			"context": saved_context,
			"timestamp": Time.get_ticks_msec()
		})
		state_pushed.emit(current_state, state_stack.size())
	
	_set_state.call_deferred(state_name)


func pop_state() -> Dictionary:
	if state_stack.is_empty():
		push_warning("Cannot pop state: stack is empty")
		return {}
	
	var previous_entry = state_stack.pop_back()
	var from_state = current_state
	
	# Restore parent state
	_set_state.call_deferred(previous_entry.state)
	
	# Restore substate if it was saved
	if previous_entry.context.has("_substate") and previous_entry.context._substate != "":
		var substate_name = previous_entry.context._substate
		if substates.has(previous_entry.state):
			# Use call_deferred to ensure parent state is set first
			_restore_substate.call_deferred(previous_entry.state, substate_name)
	
	state_popped.emit(from_state, previous_entry.state, state_stack.size())
	
	return previous_entry.context


func peek_stack() -> Dictionary:
	if state_stack.is_empty():
		return {}
	return state_stack.back().duplicate()


func peek_stack_at(depth: int) -> Dictionary:
	if depth < 0 or depth >= state_stack.size():
		return {}
	return state_stack[state_stack.size() - 1 - depth].duplicate()


func get_stack_states() -> Array[String]:
	var states: Array[String] = []
	for entry in state_stack:
		states.append(entry.state)
	return states


func get_full_stack() -> Array[Dictionary]:
	return state_stack.duplicate()


func clear_stack() -> void:
	state_stack.clear()
	stack_cleared.emit()


func get_stack_size() -> int:
	return state_stack.size()


func is_stack_empty() -> bool:
	return state_stack.is_empty()


func set_max_stack_size(size: int) -> void:
	max_stack_size = size


func replace_state(state_callable: Callable) -> void:
	change_state(state_callable)


func pop_to_depth(target_depth: int) -> Array[Dictionary]:
	var popped_contexts: Array[Dictionary] = []
	
	while state_stack.size() > target_depth and !state_stack.is_empty():
		popped_contexts.append(pop_state())
	
	return popped_contexts


func pop_to_state(state_callable: Callable) -> bool:
	var target_state = state_callable.get_method()
	
	for i in range(state_stack.size() - 1, -1, -1):
		if state_stack[i].state == target_state:
			var depth_to_pop = state_stack.size() - i - 1
			for j in range(depth_to_pop):
				state_stack.pop_back()
			pop_state()
			return true
	
	push_warning("State '%s' not found in stack" % target_state)
	return false


func is_state_in_stack(state_callable: Callable) -> bool:
	var state_name = state_callable.get_method()
	for entry in state_stack:
		if entry.state == state_name:
			return true
	return false


func get_state_depth(state_callable: Callable) -> int:
	var state_name = state_callable.get_method()
	for i in range(state_stack.size() - 1, -1, -1):
		if state_stack[i].state == state_name:
			return state_stack.size() - 1 - i
	return -1


# =============================================================================
# INTERNAL METHODS
# =============================================================================

func _set_state(state_name: String) -> void:
	# Leave old state and its substates
	if current_state:
		# Leave substate first if it exists
		if substates.has(current_state):
			var child_fsm = substates[current_state]
			if child_fsm.current_state:
				# Trigger leave on child state
				child_fsm._leave_current_state()
		
		# Leave parent state
		var leave_callable = state_dictionary[current_state].leave as Callable
		if !leave_callable.is_null():
			leave_callable.call()
	
	# Enter new parent state
	current_state = state_name
	var enter_callable = state_dictionary[current_state].enter as Callable
	if !enter_callable.is_null():
		enter_callable.call()
	
	# Enter default substate if this state has substates
	if substates.has(current_state):
		var child_fsm = substates[current_state]
		# Restore previous substate or use current one
		if !active_substates.has(current_state) and child_fsm.current_state:
			# Trigger enter on existing substate
			child_fsm._enter_current_state()


func _leave_current_state() -> void:
	if current_state:
		var leave_callable = state_dictionary[current_state].leave as Callable
		if !leave_callable.is_null():
			leave_callable.call()


func _enter_current_state() -> void:
	if current_state:
		var enter_callable = state_dictionary[current_state].enter as Callable
		if !enter_callable.is_null():
			enter_callable.call()


func _restore_substate(parent_state: String, substate_name: String) -> void:
	if substates.has(parent_state):
		var child_fsm = substates[parent_state]
		# Find the state callable by name
		for state_key in child_fsm.state_dictionary.keys():
			if state_key == substate_name:
				# Manually set the state
				child_fsm._set_state(substate_name)
				break


func get_current_substate_name() -> String:
	if substates.has(current_state):
		return substates[current_state].current_state
	return ""


func _on_substate_changed(substate: String, parent_name: String) -> void:
	active_substates[parent_name] = substate
	substate_changed.emit(parent_name, substate)
