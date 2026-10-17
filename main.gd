extends Node

var players : Array = [3,0]
var controllers : Array = [0,1]

func player_died(player):
	Engine.time_scale = 0.1
	create_tween().tween_property(Engine,'time_scale',1,1)
