extends Camera2D

@export var objectives : Array[Node2D]
@export var min_zoom : float
@export var shake_fade_speed : float
var shake_time : float


func _ready() -> void:
	for i in objectives:
		i.connect('hit_taken',shake)
func _process(delta: float) -> void:
	var thing = calculate_center()
	var center = thing[0]
	var cam_zoom = calculate_zoom(thing[1])
	zoom = Vector2(cam_zoom,cam_zoom)
	
	if shake_time <= 0:
		global_position = center
	else:
		global_position = center + Vector2(randf_range(-1,1),randf_range(-1,1))*shake_time
		shake_time -= shake_fade_speed*delta

func calculate_center():
	var positions : Array = [
		Vector2(576,324)
	]
	for objective in objectives:
		positions.append(objective.global_position)
	var final_pos : Vector2
	for i in positions:
		final_pos += i
	final_pos = final_pos/positions.size()
	return [final_pos,positions]
func calculate_zoom(positions):
	var largest_distance : float = 0
	for x in positions:
		for y in positions:
			if x.distance_to(y) > largest_distance:
				largest_distance = x.distance_to(y)
	var value = remap(largest_distance,0,1664,1,min_zoom)
	value = clamp(value,min_zoom,1)
	
	return value
func shake(bleh,bleh2,strength):
	shake_time += strength * 0.2
