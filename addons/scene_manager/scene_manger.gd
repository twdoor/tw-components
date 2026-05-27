@icon("res://addons/scene_manager/icon_scene_manager.png")
class_name SceneManager extends Node

@export var world_2d: Node2D
@export var world_3d: Node3D
@export var gui: CanvasLayer

var current_2d_scene: Node2D
var current_3d_scene: Node3D
var current_gui_scene: CanvasLayer


func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
		if !gui: return
	
		if current_gui_scene:
			if delete:
				current_2d_scene.queue_free()
			elif keep_running:
				current_gui_scene.visible = false
			else:
				gui.remove_child(current_gui_scene)
		var new = load(new_scene).instantiate()
		gui.add_child(new)
		current_gui_scene = new
		
func change_2d_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
		if !world_2d: return
	
		if current_2d_scene:
			if delete:
				current_2d_scene.queue_free()
			elif keep_running:
				current_2d_scene.visible = false
			else:
				world_2d.remove_child(current_2d_scene)
		var new = load(new_scene).instantiate()
		world_2d.add_child(new)
		current_2d_scene = new

func change_3d_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
		if !world_3d: return
	
		if current_3d_scene:
			if delete:
				current_3d_scene.queue_free()
			elif keep_running:
				current_3d_scene.visible = false
			else:
				world_3d.remove_child(current_3d_scene)
		var new = load(new_scene).instantiate()
		world_3d.add_child(new)
		current_3d_scene = new
