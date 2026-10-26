extends Node2D

var parent : CharacterBody2D
var objective : CharacterBody2D
var damage : float
var ticks : int

func _on_timer_timeout() -> void:
	ticks -= 1
	objective.hurt(
		damage,
		Vector2.ZERO,
		0
	)
	parent.enemy_damaged(damage)
	if ticks <= 0:
		parent.glitches.erase(self)
		$Timer.stop()
		$CPUParticles2D.emitting = false
		$CPUParticles2D.connect("finished",queue_free)
		top_level = true
		global_position = objective.global_position
		
func explode():
	objective.hurt(
		damage*ticks,
		Vector2(randf_range(1,-1),randf_range(1,-1)).normalized(),
		20*ticks
	)
	parent.glitches.erase(self)
	$Timer.stop()
	$CPUParticles2D.hide()
	$CPUParticles2D2.emitting = true
	$CPUParticles2D2.connect("finished",queue_free)
	top_level = true
	global_position = objective.global_position
	
