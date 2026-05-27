class_name CallableStateMachinePDA

signal state_changed(state: String)
signal state_pushed(state: String, stack_size: int)
signal state_popped(from_state: String, to_state: String, stack_size: int)
signal stack_cleared()

var state_dictionary = {}
var current_state: String:
	set(value):
		current_state = value
		state_changed.emit(value)


var state_stack: Array[Dictionary] = []
var max_stack_size: int = -1


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
		(state_dictionary[current_state].normal as Callable).call()


func change_state(state_callable: Callable) -> void:
	var state_name = state_callable.get_method()
	if state_dictionary.has(state_name):
		_set_state.call_deferred(state_name)
	else:
		push_warning("No state with name " + state_name)


## Push current state to stack and transition to new state
## context_data: Optional dictionary to store with this state transition
func push_state(state_callable: Callable, context_data: Dictionary = {}) -> void:
	var state_name = state_callable.get_method()
	if !state_dictionary.has(state_name):
		push_warning("No state with name " + state_name)
		return
	
	if max_stack_size > 0 and state_stack.size() >= max_stack_size:
		push_warning("Stack size limit reached (%d)" % max_stack_size)
		return
	
	if current_state:
		state_stack.push_back({
			"state": current_state,
			"context": context_data.duplicate(),
			"timestamp": Time.get_ticks_msec()
		})
		state_pushed.emit(current_state, state_stack.size())
	
	_set_state.call_deferred(state_name)


## Pop from stack and return to previous state
## Returns the context data from the popped state, or empty dict if stack is empty
func pop_state() -> Dictionary:
	if state_stack.is_empty():
		push_warning("Cannot pop state: stack is empty")
		return {}
	
	var previous_entry = state_stack.pop_back()
	var from_state = current_state
	
	_set_state.call_deferred(previous_entry.state)
	state_popped.emit(from_state, previous_entry.state, state_stack.size())
	
	return previous_entry.context


## Peek at the top of the stack without popping
## Returns dictionary with "state" and "context" keys, or empty dict if stack is empty
func peek_stack() -> Dictionary:
	if state_stack.is_empty():
		return {}
	return state_stack.back().duplicate()


## Peek at a specific depth in the stack (0 = top, 1 = second from top, etc.)
func peek_stack_at(depth: int) -> Dictionary:
	if depth < 0 or depth >= state_stack.size():
		return {}
	return state_stack[state_stack.size() - 1 - depth].duplicate()


## Get the entire stack as an array of state names (for debugging/display)
func get_stack_states() -> Array[String]:
	var states: Array[String] = []
	for entry in state_stack:
		states.append(entry.state)
	return states


## Get the full stack with all context data
func get_full_stack() -> Array[Dictionary]:
	return state_stack.duplicate()


## Clear the entire stack
func clear_stack() -> void:
	state_stack.clear()
	stack_cleared.emit()


## Get current stack size
func get_stack_size() -> int:
	return state_stack.size()


## Check if stack is empty
func is_stack_empty() -> bool:
	return state_stack.is_empty()


## Set maximum stack size (-1 for unlimited)
func set_max_stack_size(size: int) -> void:
	max_stack_size = size


## Replace current state without affecting the stack
func replace_state(state_callable: Callable) -> void:
	change_state(state_callable)


## Pop multiple states at once and return to a specific depth
## Returns array of context data from all popped states
func pop_to_depth(target_depth: int) -> Array[Dictionary]:
	var popped_contexts: Array[Dictionary] = []
	
	while state_stack.size() > target_depth and !state_stack.is_empty():
		popped_contexts.append(pop_state())
	
	return popped_contexts


## Pop states until we find a specific state, then transition to it
## Returns true if state was found and popped to, false otherwise
func pop_to_state(state_callable: Callable) -> bool:
	var target_state = state_callable.get_method()
	
	for i in range(state_stack.size() - 1, -1, -1):
		if state_stack[i].state == target_state:
			var depth_to_pop = state_stack.size() - i - 1
			for j in range(depth_to_pop):
				state_stack.pop_back()
			# Now pop to this state
			pop_state()
			return true
	
	push_warning("State '%s' not found in stack" % target_state)
	return false


## Check if a specific state exists in the stack
func is_state_in_stack(state_callable: Callable) -> bool:
	var state_name = state_callable.get_method()
	for entry in state_stack:
		if entry.state == state_name:
			return true
	return false


## Get the depth of a specific state in the stack (-1 if not found)
## 0 = top of stack, 1 = second from top, etc.
func get_state_depth(state_callable: Callable) -> int:
	var state_name = state_callable.get_method()
	for i in range(state_stack.size() - 1, -1, -1):
		if state_stack[i].state == state_name:
			return state_stack.size() - 1 - i
	return -1


func _set_state(state_name: String) -> void:
	if current_state:
		var leave_callable = state_dictionary[current_state].leave as Callable
		if !leave_callable.is_null():
			leave_callable.call()
	
	current_state = state_name
	var enter_callable = state_dictionary[current_state].enter as Callable
	if !enter_callable.is_null():
		enter_callable.call()
