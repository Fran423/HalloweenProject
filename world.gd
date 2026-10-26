extends Node2D

@export var players: Array[CharacterBody2D]
var player_instance_guide : Array = ["uid://c0m1qb1p0ax6u", #template
									"uid://8hsq7d24hak3",   #slenderman
									"uid://qbc78itl6n37",   #jeff the killer
									"uid://dkxdygpk0mtob",  #cartoon cat
									"uid://dx1a2bf4avhb3"]  #princess

var themes : Array[Dictionary] = [
	{
		'Name' = 'It\'s TV Time!',
		'Source' = 'DELTARUNE',
		'Directory' = 'uid://cojjpwjp61wul',
		'Start point' = 6.5
	},
	{
		'Name' = 'Danse Macabre',
		'Source' = 'ULTRAKILL',
		'Directory' = 'uid://bv3dc2opfifia',
		'Start point' = 5.88
	},
	{
		'Name' = 'Chaos King',
		'Source' = 'DELTARUNE',
		'Directory' = 'uid://bs40j2vp4nuao',
		'Start point' = 16.38
	},
	{
		'Name' = 'Won\'t you hear my Symphony?',
		'Source' = 'Nullscape',
		'Directory' = 'uid://bxf57o4t7t08h',
		'Start point' = 17
	},
	{
		'Name' = 'RETALIATION',
		'Source' = 'Grace',
		'Directory' = 'uid://ccqwg5sbkws1h',
		'Start point' = 12.94
	}
]
var current_song : Dictionary

func showdown_check():
	if Main.dead_players == Main.players.size()-2:
		showdown_start()

func showdown_start():
	$SuddenDeath.show()
	create_tween().tween_property($SuddenDeath,'color',Color(1.0, 1.0, 1.0, 0.0),1)
	create_tween().tween_property($SuddenDeath,'scale.x',1.2,1)
	create_tween().tween_property($Music,'pitch_scale',1.2,1)

func song_finished():
	var song = pick_song()
	$Music.stream = load(song['Directory'])
	$Music.play()

func _ready() -> void:
	Main.connect('dead_player',showdown_check)
	Main.connect('finish',finish)
	await get_tree().create_timer(2,false).timeout
	var song = pick_song()
	$Music.stream = load(song['Directory'])
	$Music.play(song['Start point']-3)
	create_tween().tween_property($Music,'volume_db',0,2)
	$StartAnimation.play("Start")
	create_tween().tween_property($Fade,'modulate:a',0,0.5)
	$SubViewport/Camera._connect()
	if Main.players.size() < 2:
		Main.players.append(0)
		Main.controllers.append(999)
	for i in range(Main.players.size()):
		var point : Vector2 = get_node(str('SubViewport/SpawnPoints/Player',i+1)).global_position
		var player = player_instance_guide[Main.players[i]]
		player = load(player).instantiate()
		player.global_position = point
		$SubViewport.add_child(player)
		players.append(player)
		player.player_num = i+1
		player.controller = Main.controllers[i]
		players.append(player)
		player.connect('hit_taken',hit)
		$SubViewport/Camera.objectives.append(player)
	create_tween().tween_property($SubViewport/Camera,'zoom',Vector2(2.5,2.5),3.0/players.size()-0.1).set_trans(Tween.TRANS_CUBIC)
	for character in players:
		create_tween().tween_property($SubViewport/Camera,'global_position',character.global_position,3.0/players.size()-0.1).set_trans(Tween.TRANS_CUBIC)
		await get_tree().create_timer(3.0/players.size()-0.1).timeout
	Main.started = true
	await get_tree().create_timer(players.size()*0.1).timeout
	for character in players:
		character.has_started = true

func pick_song():
	var song = themes.pick_random()
	while song == current_song:
		song = themes.pick_random()
	$Name.text = song['Name']
	$Author.text = str('(',song['Source'],')')
	return song
func finish():
	$Finish.show()
	create_tween().tween_property($Music,'pitch_scale',0.01,1)
	$SuddenDeath.hide()


func _process(delta: float) -> void:
	for player in players:
		if player != null:
			if player.global_position.y > 896 or player.global_position.x < -512 or player.global_position.x > 1664:
				if player.life > 0:
					var direction = player.global_position.direction_to(Vector2(576,320))
					player.die(direction)

func hit(damage,dir,strength):
	if strength >= 100:
		hitstop(strength)

func _input(event: InputEvent) -> void:
	$SubViewport.push_input(event)

func hitstop(strength):
	get_tree().paused = true
	for i in int(strength*0.02):
		await get_tree().process_frame
	get_tree().paused = false
