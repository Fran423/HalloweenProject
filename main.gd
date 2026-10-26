extends Node

var players : Array = [4,0,0,0]
var controllers : Array = [0,1,2,3]
var dead_players : int
var started : bool = false
signal finish
signal dead_player
func player_died(player):
	Engine.time_scale = 0.1
	dead_players += 1
	dead_player.emit()
	if dead_players > players.size()-1:
		create_tween().tween_property(Engine,'time_scale',1,1)
	else:
		finish.emit()
		await get_tree().create_timer(0.5,false).timeout
		Engine.time_scale = 1
		get_tree().change_scene_to_file("res://character_selection.tscn")
	
