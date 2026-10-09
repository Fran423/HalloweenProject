extends Node2D

@export var players: Array[CharacterBody2D]
func _ready() -> void:
	for i in players:
		i.connect('hit_taken',hit)

func hit(damage,dir,strength):
	if strength >= 100:
		hitstop(strength)

func hitstop(strength):
	get_tree().paused = true
	for i in int(strength*0.02):
		await get_tree().process_frame
	get_tree().paused = false
