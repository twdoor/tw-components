@tool
@icon("res://addons/motion_effects/icon_screen_effect.png")
class_name TrailEffect extends Line2D

@export var trail_duration: float = .5
@export var points_per_second: float = 60.0
@export var max_points: int = 20
@export var min_distance_between_points: float = 16
@export var max_distance_between_points: float = 64
@export var active: bool = true

var trail_points: Array[Dictionary] = []
var last_position: Vector2
var time_accumulator: float = 0.0

func _ready():
	last_position = global_position


func _process(delta: float) -> void:
	if not active:
		return
		
	time_accumulator += delta
	var time_between_points = 1.0 / points_per_second
	
	if time_accumulator >= time_between_points:
		var current_pos = global_position
		if current_pos != last_position:
			add_trail_point(current_pos)
			last_position = current_pos
		
		time_accumulator = 0.0
	
	update_trail_points(delta)
	update_line_points()


func add_trail_point(pos: Vector2):
	if not trail_points.is_empty():
		var last_point_pos = trail_points[-1]["position"]
		var distance = pos.distance_to(last_point_pos)
		
		if distance < min_distance_between_points:
			return
		
		if distance > max_distance_between_points:
			var direction = (pos - last_point_pos).normalized()
			var remaining_distance = distance
			var current_pos = last_point_pos
			
			while remaining_distance > max_distance_between_points:
				current_pos = current_pos + (direction * max_distance_between_points)
				var point_data = {
					"position": current_pos,
					"age": 0.0
				}
				trail_points.append(point_data)
				remaining_distance -= max_distance_between_points
				
				while trail_points.size() > max_points:
					trail_points.pop_front()
			
			pos = current_pos + (direction * remaining_distance)
	
	var point_data = {
		"position": pos,
		"age": 0.0
	}
	
	trail_points.append(point_data)
	while trail_points.size() > max_points:
		trail_points.pop_front()


func update_trail_points(delta: float):
	var i = 0
	while i < trail_points.size():
		trail_points[i]["age"] += delta
		
		if trail_points[i]["age"] > trail_duration:
			trail_points.remove_at(i)
		else:
			i += 1


func update_line_points():
	clear_points()
	
	if trail_points.is_empty():
		return
	
	for point_data in trail_points:
		var local_pos = to_local(point_data["position"])
		add_point(local_pos)


func clear_trail():
	trail_points.clear()
	clear_points()


func set_active(value: bool):
	active = value
	if not active:
		clear_trail()
