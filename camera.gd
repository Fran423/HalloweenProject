extends Camera2D

@export var objectives : Array[Node2D]
@export var min_zoom : float
@export var shake_fade_speed : float
@export var death_shake : float = 300
var shake_time : float


func _connect() -> void:
	await get_tree().process_frame
	for i in objectives:
		i.hit_taken.connect(func(_damage,_dir,strength) : shake(strength))
		i.dead.connect(func(_character):shake(death_shake))
func _process(delta: float) -> void:
	if Main.started:
		var thing = calculate_center() 
		var center = Vector2(clamp(thing[0].x,320,832),clamp(thing[0].y,124,376))
		var cam_zoom = calculate_zoom(thing[1])
		zoom = lerp(zoom,Vector2(cam_zoom,cam_zoom),0.1)
	
		if shake_time <= 0:
			global_position = lerp(global_position,center,0.1)
		else:
			global_position = center + Vector2(randf_range(-1,1),randf_range(-1,1))*shake_time*(1/(zoom.x*0.1))
			shake_time = lerp(shake_time,0.0,shake_fade_speed*delta)

func calculate_center():
	var positions : Array = [
		Vector2(576,324)
	]
	for objective in objectives:
		if objective != null:
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
func shake(strength):
	print(strength)
	shake_time += strength * 0.05
