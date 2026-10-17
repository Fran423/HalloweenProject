extends RigidBody2D

var damage_mult : float = 0.01
var launch_mult : float = 0.1

func _ready() -> void:
	await get_tree().create_timer(0.2,false).timeout
	$Hitbox.set_deferred('monitoring',true)
func hit(home_run : bool):
	$Bat.direction = linear_velocity.normalized()
	$Bat.global_position = global_position
	$Bat.emitting = true
	$Lifetime.stop()
	if home_run:
		gravity_scale = 0.1
	$Lifetime.start(5)

func _process(delta: float) -> void:
	if linear_velocity.length() < 50 and $Lifetime.is_stopped():
		queue_free()


func _on_lifetime_timeout() -> void:
	queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() != get_parent():
		area.get_parent().hurt(damage_mult*linear_velocity.length(),
		Vector2(linear_velocity.normalized().x,abs(linear_velocity.normalized().y)-0.5),
		launch_mult * linear_velocity.length())
		queue_free()
