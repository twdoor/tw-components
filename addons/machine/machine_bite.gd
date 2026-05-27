## MachineBite - Base class for all state machine bites
@abstract class_name MachineBite extends Node

## Reference to the parent MachineRoot (set automatically)
var root: MachineRoot

## Sub-bites (child MachineBite nodes)
var sub_bites: Array[MachineBite] = []

## Currently active sub-bite
var active_sub: MachineBite

## Parent bite (if this is a sub-bite)
var parent_bite: MachineBite


## Called internally by MachineRoot during _ready()
func _initialize_bite():
	for child in get_children():
		if child is MachineBite:
			sub_bites.append(child)
			child.parent_bite = self
			child.root = root
			child._initialize_bite()
	
	if sub_bites.size() > 0:
		active_sub = sub_bites[0]

@abstract func on_enter(ctx: MachineContext) -> void
@abstract func on_exit(ctx: MachineContext) -> void
@abstract func update(ctx: MachineContext, delta: float) -> void


func enter_bite(ctx: MachineContext) -> void:
	if active_sub:
		if root and root.active_main == self:
			root.active_sub = active_sub
		active_sub.enter_bite(ctx)
	
	on_enter(ctx)


func exit_bite(ctx: MachineContext) -> void:
	on_exit(ctx)
	if active_sub:
		active_sub.exit_bite(ctx)
		if root and root.active_main == self:
			root.active_sub = null


func _update(ctx: MachineContext, delta: float) -> void:
	if active_sub:
		active_sub._update(ctx, delta)
	update(ctx, delta)


func change_sub_bite(bite: MachineBite) -> void:
	if parent_bite:
		parent_bite.change_sub_bite(bite)
		return
	
	if not bite in sub_bites:
		push_error("MachineBite '%s': Cannot change to '%s' - not a sub-bite" % [name, bite.name])
		return
	
	if root and root.active_main == self:
		root.change_sub_bite(bite)
		active_sub = bite
	else:
		push_error("MachineBite '%s': Cannot change sub-bite - not the active main bite" % name)


## Check if this bite has a specific sub-bite by name
func has_sub_bite(bite_name: String) -> bool:
	for bite in sub_bites:
		if bite.name == bite_name:
			return true
	return false


## Get a sub-bite by name
func get_sub_bite(bite_name: String) -> MachineBite:
	for bite in sub_bites:
		if bite.name == bite_name:
			return bite
	return null


## Change to the parent root's different main bite
## Useful for transitioning from ground to air, etc.
func change_main_bite(bite: MachineBite) -> void:
	if root:
		root.change_main_bite(bite)
	else:
		push_error("MachineBite '%s': Cannot change main bite - no root reference" % name)


## Transition helper: Check a condition and change main bite if true
func transition_to_main_if(condition: bool, bite: MachineBite) -> bool:
	if condition:
		change_main_bite(bite)
		return true
	return false


## Transition helper: Check a condition and change sub bite if true
func transition_to_sub_if(condition: bool, bite: MachineBite) -> bool:
	if condition:
		change_sub_bite(bite)
		return true
	return false
