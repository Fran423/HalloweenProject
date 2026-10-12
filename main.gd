extends Node

var players : Array = [0]
var controllers : Array

func player_died(player):
	Engine.time_scale = 0.1
	create_tween().tween_property(Engine,'time_scale',1,1)
