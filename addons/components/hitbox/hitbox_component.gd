@tool @icon("uid://cjwy8gfcombo8")
class_name HitboxComponent2D extends Area2D
## A unified component that can act as either a hitbox or hurtbox.
## Uses a HitEffect resource for damage and any project-specific hit data.

## Emitted when this hitbox successfully hits a hurtbox.
## hit_effect is the fully resolved resource for this hit.
signal hit_hurtbox(hurtbox: HitboxComponent2D, hit_effect: HitEffect)
## Emitted when this hurtbox is hit by a hitbox.
## hit_effect is the fully resolved resource from the attacker.
signal hit_by_hitbox(hitbox: HitboxComponent2D, hit_effect: HitEffect)

enum Type {
	HURTBOX, ## Receives damage
	HITBOX,  ## Deals damage
}

## Type of this component
@export var type: Type = Type.HURTBOX:
	set(value):
		type = value
		_setup_collision_layers()
		_update_node_name()
		notify_property_list_changed()

## Hit payload this hitbox sends when type = HITBOX.
## Assign a project-specific HitEffect subclass to add custom data.
@export var hit_effect: HitEffect

## Collision layer to use for filtering interactions
@export_flags_2d_physics var hit_layer: int = 0:
	set(v):
		hit_layer = v
		_setup_collision_layers()

## If true, collisions are temporarily disabled
@export var disable_collisions: bool = false

## Prevents the same hitbox from dealing damage multiple times in one frame
var _hits_processed_this_frame: Dictionary = {}


func _validate_property(property: Dictionary) -> void:
	if property.name == "hit_effect" and type != Type.HITBOX:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_setup_collision_layers()
	_update_node_name()
	set_process(false)


func _setup_collision_layers() -> void:
	collision_layer = 0
	collision_mask = 0
	monitorable = false
	monitoring = false

	match type:
		Type.HITBOX:
			collision_mask = hit_layer
			monitoring = true

		Type.HURTBOX:
			collision_layer = hit_layer
			monitorable = true


func _get_hitbox_node_name() -> String:
	return "Hitbox"


func _get_hurtbox_node_name() -> String:
	return "Hurtbox"


func _update_node_name() -> void:
	if not Engine.is_editor_hint():
		return

	match type:
		Type.HITBOX:
			name = _get_hitbox_node_name()
		Type.HURTBOX:
			name = _get_hurtbox_node_name()


func _process(_delta: float) -> void:
	_hits_processed_this_frame.clear()
	set_process(false)


func _on_area_entered(other_area: Area2D) -> void:
	if disable_collisions or other_area is not HitboxComponent2D:
		return

	var hurtbox := other_area as HitboxComponent2D
	if hurtbox.type != Type.HURTBOX:
		return

	_handle_hit.call_deferred(hurtbox)


func _handle_hit(hurtbox: HitboxComponent2D) -> void:
	if _hits_processed_this_frame.has(hurtbox.get_instance_id()):
		return
	_hits_processed_this_frame[hurtbox.get_instance_id()] = true
	set_process(true)

	var resolved_effect := get_hit_effect()

	hit_hurtbox.emit(hurtbox, resolved_effect)
	hurtbox._notify_hit_by(self, resolved_effect)


func _notify_hit_by(hitbox: HitboxComponent2D, resolved_hit_effect: HitEffect) -> void:
	hit_by_hitbox.emit(hitbox, resolved_hit_effect)


## Compatibility helper for code that only needs damage.
func get_hit_damage() -> float:
	return get_hit_effect().damage


## Override in subclasses to resolve per-frame/per-shape hit effects.
## Returns a new resource each call so receivers can modify it safely.
func get_hit_effect() -> HitEffect:
	if hit_effect:
		return hit_effect.duplicate_for_hit()
	return HitEffect.new()


## Temporarily disable this component from processing collisions
func disable() -> void:
	disable_collisions = true


## Re-enable collision processing
func enable() -> void:
	disable_collisions = false
