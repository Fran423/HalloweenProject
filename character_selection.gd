extends Control

var controllers : Array
var pickers : Array[Dictionary] = []
@export var picker_speed : float
var picker_template : CharacterBody2D

func _ready() -> void:
	Input.joy_connection_changed.connect(device_connected)
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
		var picker = picker_template.duplicate()
		var picker_data = {'cursor' = picker,'controller_id' = controllers[i],'player_number' = i+1,'selection' = null,'marked' = false}
		add_child(picker)
		pickers.append(picker_data)
		
func _process(delta: float) -> void:
	if !$StartTime.is_stopped():
		$Label.text = str(int($StartTime.time_left)+1)
		
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
	$Players.get_node(str('Player',picker['player_number'])).text = character
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		for picker in pickers:
			if picker['controller_id'] == event.device:
				picker['marked'] = !picker['marked']
				start_button(marks_check())
				break

func device_connected(device, connected):
	if connected and pickers.size() < 4:
		if device in controllers:
			return
		var picker = picker_template.duplicate()
		picker.global_position = Vector2(576,320)
		add_child(picker)
		var picker_data = {'cursor' = picker,'controller_id' = device,'player_number' = null,'selection' = null,'marked' = false}
		picker_data['player_number'] = pickers.size()+1
		for i in pickers.size():
			if pickers[i]['player_number'] != i+1:
				picker_data['player_number'] = i+1
				break
		pickers.append(picker_data)
		controllers.append(device)
		
		print('detected new joypad:',device,' Total:',controllers)
	if !connected and device in controllers:
		var dictionary = {'cursor' = null,'controller_id' = null,'player_number' = null,'selection' = null,'marked' = false}
		for picker in pickers:
			if picker['controller_id'] == device:
				dictionary = picker
				break
		if dictionary['cursor'] == null:
			return
		dictionary['cursor'].queue_free()
		dictionary['selection'] = 0
		dictionary['marked'] = false
		change_selection(dictionary)
		pickers.erase(dictionary)
		controllers.erase(device)
		print('joypad disconnected:',device,' Total:',controllers)
	start_button(marks_check())

func marks_check():
	for picker in pickers:
		if picker['marked'] == false:
			return false
	if pickers.size() <= 0:
		return false
	return true
func start_button(ready : bool):
	if ready: 
		print('ready')
		$StartTime.start()
	else:
		print('not ready')
		$Label.text = 'not ready'
		$StartTime.stop()

func _on_start_time_timeout() -> void:
	var players : Array
	for picker in pickers:
		if picker['selection'] == 0:
			print('Error: one player doesn\' have a character selected.')
			return
		else:
			players.append(picker['selection'])
	Main.players = players
	print(Main.players)
