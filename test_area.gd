extends Node2D

@export var players: Array[CharacterBody2D]
func _ready() -> void:
	for i in players:
		i.connect('hit_taken',hit)

func _process(delta: float) -> void:
	for player in players:
		if player.global_position.y > 832 or player.global_position.x < -384 or player.global_position.x > 1536:
			if player.life > 0:
				var direction = player.global_position.direction_to(Vector2(576,320))
				player.die(direction)

func hit(damage,dir,strength):
	if strength >= 100:
		hitstop(strength)

func hitstop(strength):
	get_tree().paused = true
	for i in int(strength*0.02):
		await get_tree().process_frame
	get_tree().paused = false
