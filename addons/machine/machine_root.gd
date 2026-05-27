class_name MachineRoot extends Node

@export var context_script: Script
## The active context instance for this root
var context: MachineContext

## Main-level bites (direct children, like GroundBite, AirBite)
var main_bites: Array[MachineBite] = []

## Currently active main bite
var active_main: MachineBite

## Currently active sub-bite (child of active_main)
var active_sub: MachineBite

## Emitted when a bite becomes active
signal bite_entered(bite: MachineBite)

## Emitted when a bite becomes inactive
signal bite_exited(bite: MachineBite)

## Emitted when switching between bites
signal bite_changed(from: MachineBite, to: MachineBite)


func _ready():
	_initialize()


func _initialize():
	if context_script:
		context = context_script.new()
		if context == null:
			push_error("MachineRoot: Failed to create context from script: " + str(context_script))
			return
	
	for child in get_children():
		if child is MachineBite:
			main_bites.append(child)
			child.root = self
			child._initialize_bite()
	
	if main_bites.size() > 0 and context:
		change_main_bite(main_bites[0])


func update_machine(delta: float):
	if context and active_main:
		active_main._update(context, delta)


## Change the active main bite
## Automatically exits current main and sub bites
func change_main_bite(bite: MachineBite) -> void:
	if not bite in main_bites:
		push_error("MachineRoot: Bite '%s' is not a main bite of this root" % bite.name)
		return
	
	var previous = active_main
	
	if active_sub:
		active_sub.exit_bite(context)
		bite_exited.emit(active_sub)
		active_sub = null

	if active_main:
		active_main.exit_bite(context)
		bite_exited.emit(active_main)
	
	active_main = bite
	bite.enter_bite(context)
	bite_entered.emit(bite)
	
	if previous:
		bite_changed.emit(previous, bite)


## Change the active sub-bite (must be called by the active main bite)
## Called internally by MachineBite.change_sub_bite()
func change_sub_bite(bite: MachineBite) -> void:
	if not active_main:
		push_error("MachineRoot: Cannot change sub-bite without an active main bite")
		return
	
	if not bite in active_main.sub_bites:
		push_error("MachineRoot: Bite '%s' is not a sub-bite of '%s'" % [bite.name, active_main.name])
		return
	
	var previous = active_sub
	
	if active_sub:
		active_sub.exit_bite(context)
		bite_exited.emit(active_sub)
	
	active_sub = bite
	bite.enter_bite(context)
	bite_entered.emit(bite)
	
	if previous:
		bite_changed.emit(previous, bite)



func get_active_path() -> String:
	var path = name
	if active_main:
		path += " -> " + active_main.name
		if active_sub:
			path += " -> " + active_sub.name
	return path
