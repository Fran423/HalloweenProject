extends CharacterBody2D

func _ready() -> void:
	$Timer.connect('timeout',destroy)


func destroy():
	$CPUParticles2D.hide()
	$CPUParticles2D2.emitting = true
	$CPUParticles2D2.connect("finished",queue_free)
	for area in $AttackHitbox.get_overlapping_areas():
		if area.get_parent() != get_parent():
			area.get_parent().hurt(
				0,
				global_position.direction_to(area.global_position),
				100
			)
	$Sprite2D.hide()
