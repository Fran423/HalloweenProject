extends Node2D

@export var players: Array[CharacterBody2D]
var player_instance_guide : Array = ["uid://qbc78itl6n37","uid://qbc78itl6n37","uid://qbc78itl6n37","uid://dkxdygpk0mtob","uid://qbc78itl6n37"]

func _ready() -> void:
	for i in players:
		i.connect('hit_taken',hit)
	for i in range(Main.players.size()):
		var point : Vector2 = get_node(str('SubViewport/SpawnPoints/Player',i+1)).global_position
		var player = player_instance_guide[Main.players[i]]
		player = load(player).instantiate()
		player.global_position = point
		$SubViewport.add_child(player)
		players.append(player)
		$SubViewport/Camera.objectives.append(player)

func _process(delta: float) -> void:
	for player in players:
		if player != null:
			if player.global_position.y > 832 or player.global_position.x < -512 or player.global_position.x > 1664:
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
