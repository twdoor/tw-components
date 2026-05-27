# tw_components

A personal collection of reusable Godot 4 components, resources, and helper nodes.

This repository is not a single editor plugin. Most files under `addons/` expose `class_name` scripts that can be copied into a Godot project and used directly from the Create Node / Create Resource dialogs.

The project currently targets Godot `4.5`.

## Installation

1. Copy the folders you want from `addons/` into your Godot project's `res://addons/` folder.
2. Reopen the project or reload scripts so Godot registers the `class_name` types.
3. Add the components as nodes/resources from the editor, or instantiate them from code.

There are no `plugin.cfg` files in the current addon set, so there is normally nothing to enable in `Project > Project Settings > Plugins`.

If this repository project complains about missing plugins after removing third-party addons, remove stale entries from the `[editor_plugins]` section of `project.godot`.

## Addons

| Folder | Main classes | Purpose |
| --- | --- | --- |
| `addons/components/health` | `HealthComponent` | Node-based health with change, increase, decrease, and depleted signals. |
| `addons/components/hitbox` | `HitboxComponent2D`, `HitboxComponent3D`, `FrameDataHitbox2D`, `HitEffect`, `FrameData`, `FrameShape` | 2D/3D hitbox and hurtbox components, plus frame-based attack hitboxes. |
| `addons/stats` | `Stats`, `Stat`, `StatMod` | Resource-based stats with level scaling, curves, additive mods, and multiplicative mods. |
| `addons/callable_state_machine` | `CallableStateMachine`, `CallableStateMachinePDA`, `HierarchicalStateMachine` | Callable-driven finite state machines, with pushdown stack and hierarchy variants. |
| `addons/machine` | `MachineRoot`, `MachineBite`, `MachineContext` | Node-tree state machine using child bite nodes and a shared context object. |
| `addons/inventory_components_2` | `Inventory`, `InventorySlot`, `InventoryData`, `SlotData`, `ItemData` | Basic UI inventory, slot resources, item resources, stack merging, and slot interaction signals. |
| `addons/sequence_nodes` | `Sequence`, `TreeSequence` | Play ordered, reverse, full, or random animation/state-machine sequences. |
| `addons/scene_manager` | `SceneManager` | Switch 2D, 3D, and GUI scenes into assigned container nodes. |
| `addons/scenes` | `scene_loader.gd`, `loading_screen.gd` | Threaded scene loading helper and loading screen scene. |
| `addons/color_palette` | `ColorPaletteMaker`, `ColorButton` | Grid-based color palette UI with callback-based color requests. |
| `addons/motion_effects` | `TrailEffect` | Line2D trail effect for moving 2D nodes. |

## Health

Add a `HealthComponent` node to anything that needs health.

```gdscript
@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	health.setup_component(100)
	health.health_depleated.connect(_on_depleted)

func take_damage(amount: float) -> void:
	health.health -= amount
```

Signals:

- `health_changed(old_value, new_value)`
- `health_decreased(by_value)`
- `health_increased(by_value)`
- `health_depleated()`
- `max_health_changed(old_value, new_value)`

## Hitboxes

`HitboxComponent2D` and `HitboxComponent3D` are unified hitbox/hurtbox nodes.

Set `type` to:

- `HURTBOX` to receive hits.
- `HITBOX` to deal hits.

Use `hit_layer` to match hitboxes against hurtboxes. A hitbox sets its collision mask, and a hurtbox sets its collision layer.

```gdscript
func _ready() -> void:
	$Hitbox.hit_hurtbox.connect(_on_hit_hurtbox)
	$Hurtbox.hit_by_hitbox.connect(_on_hit_by_hitbox)

func _on_hit_hurtbox(hurtbox: HitboxComponent2D, effect: HitEffect) -> void:
	print("Hit for ", effect.damage)

func _on_hit_by_hitbox(hitbox: HitboxComponent2D, effect: HitEffect) -> void:
	health.health -= effect.damage
```

`HitEffect` is a resource with a `damage` value. Extend it in your project if a hit needs extra data such as knockback, stun, element, team, or hitstop.

### Frame Data Hitboxes

`FrameDataHitbox2D` extends `HitboxComponent2D` and adds frame-by-frame collision shapes for animated attacks.

In the editor, add a `FrameDataHitbox2D`, then use its inspector buttons:

- `Add Single Frame`
- `Add Multi-Frame (2 Hitboxes)`
- `Add Multi-Frame (3 Hitboxes)`
- `Add Empty Frame`
- `Remove Last Frame`
- `Clear All Frames`

Each generated `FrameShape` can also add/remove hitboxes or insert frames around itself.

At runtime, drive frames from your animation or attack script:

```gdscript
@onready var attack_box: FrameDataHitbox2D = $FrameDataHitbox2D

func start_attack() -> void:
	attack_box.reset_frames()
	attack_box.enable()

func advance_attack_frame() -> void:
	attack_box.next_frame()

func end_attack() -> void:
	attack_box.disable_all()
```

Hit effect priority is:

1. Active `FrameShape.hit_effect_override`
2. Current `FrameData.hit_effect_override`
3. Base `HitboxComponent2D.hit_effect`

## Stats

`Stats` is a resource for level-scaled stat values and modifiers.

```gdscript
var stats := Stats.new()

func _ready() -> void:
	stats.base_max_health = 20
	stats.max_level = 30
	stats.setup_stats()
	stats.health_changed.connect(_on_health_changed)

func equip_bonus() -> void:
	var mod := StatMod.new(Stats.StatTag.MAX_HEALTH, 5.0, StatMod.ModType.ADD)
	stats.add_mod(mod)
```

Current built-in stat tags:

- `MAX_HEALTH`

`StatMod.ModType.ADD` adds to a stat. `StatMod.ModType.MULTIPLY` increases the multiplier total.

## Callable State Machines

The callable state machines store state behavior as `Callable`s. The callable method name becomes the state name.

```gdscript
var fsm := CallableStateMachine.new()

func _ready() -> void:
	fsm.add_states(idle, enter_idle, leave_idle)
	fsm.add_states(run)
	fsm.set_initial_state(idle)

func _physics_process(_delta: float) -> void:
	fsm.update()

func idle() -> void:
	if Input.is_action_pressed("ui_right"):
		fsm.change_state(run)

func enter_idle() -> void:
	pass

func leave_idle() -> void:
	pass

func run() -> void:
	if !Input.is_action_pressed("ui_right"):
		fsm.change_state(idle)
```

Variants:

- `CallableStateMachine`: basic finite state machine.
- `CallableStateMachinePDA`: adds push/pop stack behavior for temporary states such as pause, hitstun, menus, or interrupts.
- `HierarchicalStateMachine`: adds nested state machines and pushdown behavior.

## Machine Bites

The `machine` addon is a node-tree state machine.

Use a `MachineRoot` node with direct `MachineBite` children for main states. A main bite can have child `MachineBite` nodes for substates. Assign a script that extends `MachineContext` to `MachineRoot.context_script`.

```gdscript
extends MachineBite

func on_enter(ctx: MachineContext) -> void:
	pass

func on_exit(ctx: MachineContext) -> void:
	pass

func update(ctx: MachineContext, delta: float) -> void:
	if should_jump:
		change_main_bite(root.get_node("Air"))
```

Call `update_machine(delta)` from the owner:

```gdscript
func _physics_process(delta: float) -> void:
	$MachineRoot.update_machine(delta)
```

## Inventory

The inventory addon uses resource data and UI scenes.

- `ItemData`: item name, description, max stack, and texture.
- `SlotData`: item plus quantity.
- `InventoryData`: array of slots, grab/drop helpers, and interaction signals.
- `Inventory`: UI container that displays an `InventoryData`.
- `InventorySlot`: button-based slot UI.

```gdscript
@export var inventory_data: InventoryData
@onready var inventory: Inventory = $Inventory

func _ready() -> void:
	inventory.set_inventory_data(inventory_data)
	inventory_data.inventory_interact.connect(_on_inventory_interact)
```

`InventorySlot` currently uses the input actions named `test1` and `test2` for use/inspect-style interactions. Rename or remap these in your project as needed.

## Animation Sequences

`Sequence` plays animations from an `AnimationPlayer`.

```gdscript
@onready var sequence: Sequence = $Sequence

func play_combo() -> void:
	await sequence.play_sequence()
```

`TreeSequence` does the same for `AnimationTree` state machines. It can discover state machine paths and state names in the editor.

Run orders:

- `FORWARD`
- `BACKWARD`
- `FULL`
- `RANDOM`

## Scene Helpers

`SceneManager` swaps packed scenes into assigned containers:

- `world_2d: Node2D`
- `world_3d: Node3D`
- `gui: CanvasLayer`

```gdscript
$SceneManager.change_2d_scene("res://levels/level_01.tscn")
$SceneManager.change_gui_scene("res://ui/pause_menu.tscn", false, true)
```

`addons/scenes/scene_loader.gd` provides threaded loading with a loading screen. Call `load_scene(path)` to show the loading screen, request the scene on a background thread, emit progress, and switch when loading finishes.

## Color Palette

`ColorPaletteMaker` builds a grid of `ColorButton`s from its exported `colors` array.

```gdscript
func _ready() -> void:
	$ColorPaletteMaker.setup_palette()
	$ColorPaletteMaker.request_color(_on_color_picked)

func _on_color_picked(color: Color) -> void:
	print(color)
```

## Trail Effect

Add `TrailEffect` as a `Line2D`-based node that follows its own global position over time.

Useful exports:

- `trail_duration`
- `points_per_second`
- `max_points`
- `min_distance_between_points`
- `max_distance_between_points`
- `active`

```gdscript
$TrailEffect.set_active(true)
$TrailEffect.clear_trail()
```

## Attribution

Some addons are modified, expanded, or inspired by other developers' work:

- `addons/stats` is a modification of the stats addon by Queble.
- `addons/callable_state_machine` is a modification and expansion of the callable state machine by Firebelly Studio.
- `addons/components/hitbox` frame-data hitboxes were heavily inspired by examples shown by Inbound Shovel.

Third-party addons that were previously present in this project have been removed.

## License

This repository currently includes an MIT license in `LICENSE`.
