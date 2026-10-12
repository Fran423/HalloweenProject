extends Control

var controllers : Array
var pickers : Array[Dictionary] = []
@export var picker_speed : float
var picker_template : CharacterBody2D

func _ready() -> void:
	picker_template = $Player.duplicate()
	$Player.queue_free()
	var joypads = Input.get_connected_joypads()
	if joypads.size() <= 4:
		controllers = Input.get_connected_joypads()
	else:
		for i in range(4):
			controllers.append(joypads[i])
	print('initial controllers:',controllers)
	for i in range(controllers.size()):
		var picker = picker_template
		picker.name = str(picker.name,i+1)
		add_child(picker)
		pickers.append({'cursor' = picker,'controller_id' = controllers[i],'player_number' = i+1,'selection' = null,'marked' = false})
		
func _process(delta: float) -> void:
	for i in pickers:
		i['cursor'].velocity.x = Input.get_joy_axis(i['controller_id'],JOY_AXIS_LEFT_X)*picker_speed
		i['cursor'].velocity.y = Input.get_joy_axis(i['controller_id'],JOY_AXIS_LEFT_Y)*picker_speed
		i['cursor'].move_and_slide()
		if i['marked'] == false:
			i['cursor'].get_node('Sprite2').global_position = i['cursor'].global_position
			if i['selection'] != check_selection(i):
				i['selection'] = check_selection(i)
				change_selection(i)

func check_selection(picker):
	var cursor : CharacterBody2D = picker['cursor']
	var character_selected : int = 0
	if int(cursor.global_position.y) in range(228, 228+$HBoxContainer.size.y):
		if int(cursor.global_position.x) in range(305, 436):
			character_selected = 1
		if int(cursor.global_position.x) in range(436, 574):
			character_selected = 2
		if int(cursor.global_position.x) in range(574, 708):
			character_selected = 3
		if int(cursor.global_position.x) in range(708, 846):
			character_selected = 4
	else:
		character_selected = 0
	return character_selected

func change_selection(picker):
	var character : String
	match picker['selection']:
		0:
			character = 'nobody selected'
		1:
			character = 'slenderman'
		2:
			character = 'jeff the killer'
		3:
			character = 'cartoon cat'
		4:
			character = 'princess'
	$Players.get_node(str(picker['cursor'].name)).text = character
	
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		for picker in pickers:
			if event.device == picker['controller_id']:
				return
		print('detected new joypad:',event.device,' Total:',controllers)
		var picker = picker_template
		picker.global_position = Vector2(576,320)
		add_child(picker)
		
		pickers.append({'cursor' = picker,'controller_id' = event.device,'player_number' = pickers.size()+1,'selection' = null,'marked' = false})
