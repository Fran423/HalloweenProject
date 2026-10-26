extends CharacterBody2D

@export_category('Stats')
@export var jump_force : float
@export var jump_max_height : float
@export var num_of_extra_jumps : int
@export var side_speed : float
@export var accel : float
@export var max_fall_speed : float
@export var weight : float
@export var max_life : float

@export_category('Tweaks')
@export_range(0,1) var dead_zone : float 
@export var leap_strength : float
@export var coyote_max_time : float
@export var taunt_time : float

@export_category('Cooldowns')
@export var taunt_cooldown : float

@export_category('Upper')
@export var up_tentacle_power : float
@export var up_tentacle_jump : float
@export var up_tentacle_windup : float
@export var up_tentacle_damage : float
@export var up_tentacle_strength : float

@export_category('Side')
@export var swing_windup : float
@export var swing_fail_punishment : float
@export var swing_damage : float
@export var swing_strength : float

@export_category('Neutral')
@export var note_lifetime : float
@export var note : PackedScene
var note_child = null

@export_category('Down')
@export var slam_speed : float
@export var slam_damage : float
@export var slam_strength : float
@export var slam_power : float

var jumps_left : int = 0
var player_num : int
var has_started : bool = false
var controller : int
var knocked_time : float = 0
var freefall : bool = false
@onready var playback : AnimationNodeStateMachinePlayback = $AnimationTree.get('parameters/playback')
var taunt_time_left : float = 0
var cooldown_time : float = 0
var move_weight : float = 0
var can_move : bool = true
var coyote : float = 0
var vel : Vector2
var life : float
var lives : int = 3
var stage_limits : Array #[left, up, right, down]
signal hit_taken(damage,dir,strength)
signal dead

func _ready() -> void:
	$Label.text = str(max_life)
	life = max_life

func _physics_process(delta: float) -> void:
	manage_movement(delta)
	vel = velocity
	if taunt_time_left <= 0:
		if life > 0:
			move_and_slide()
		
	else:
		taunt_time_left -= delta
	if cooldown_time > 0:
		cooldown_time -= delta
	if knocked_time > 0:
		check_knockback_bounce()
		knocked_time -= delta
	
func check_knockback_bounce():

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()

		# Pared: choque horizontal
		if abs(normal.x) > abs(normal.y):
			velocity.x = -vel.x * 0.5
			

		# Suelo o techo: choque vertical
		else:
			velocity.y = -vel.y * 0.5
			velocity.x *= 0.8
		

func launch(dir: Vector2, strength: float):
	dir = dir.normalized()
	var launch_speed = strength * 10.0
	velocity = dir * launch_speed
	knocked_time = strength * remap(life,0,max_life,0.02,0.0005) * 0.6
	reboot()
	$HitParticles.emitting = true
	while knocked_time > 0:
		await get_tree().process_frame
	$HitParticles.emitting = false


func hurt(damage:float, dir:Vector2, strength:float):
	hit_taken.emit(damage, dir, strength)
	if strength > 0:
		launch(dir,strength)
	life -= damage
	$Label.text = str(life)
	if life <= 0:
		die(dir)
	else:
		$HitParticles.emitting = false
		while knocked_time > 0:
			await get_tree().process_frame

func die(dir : Vector2 = Vector2.ZERO):
	dead.emit(self)
	$HitParticles.emitting = false
	$Hurtbox.set_deferred('monitorable',false)
	$DeathParticles.direction = dir
	$DeathParticles.global_position = global_position
	$DeathParticles.emitting = true
	life = 0
	lives -= 1
	if lives > 0:
		await get_tree().create_timer(1,false).timeout
		revive()
	else:
		Main.player_died(self)
		await $DeathParticles.finished
		queue_free()

func revive():
	create_tween().tween_property(self,'global_position',Vector2(576,128),1)
	await get_tree().create_timer(2,false).timeout
	life = max_life
	$Hurtbox.set_deferred('monitorable',true)
	
	velocity = Vector2(0,-300)
	$Label.text = str(life)

	
func leap():
	if ($LeapRight2.is_colliding() or $LeapLeft2.is_colliding()) and (!$LeapRight.is_colliding() and !$LeapLeft.is_colliding()):
		if velocity.y > -leap_strength:
			velocity.y = -leap_strength
		if $LeapRight2.is_colliding():
			global_position.x += 10
		elif $LeapLeft2.is_colliding():
			global_position.x -= 10
		reboot()

func manage_movement(delta):
	if knocked_time <= 0 and taunt_time_left <= 0:
		leap()
		var dir : float = 0
		if abs(Input.get_joy_axis(Main.controllers[player_num-1],JOY_AXIS_LEFT_X)) > dead_zone and can_move and has_started:
			dir = sign(Input.get_joy_axis(controller,JOY_AXIS_LEFT_X))
		if !is_on_floor():
			if (velocity + get_gravity()*delta).y < max_fall_speed:
				velocity += get_gravity()*delta
			if Input.get_joy_axis(controller,JOY_AXIS_LEFT_Y) > 0.5 and !freefall:
				velocity.y = max_fall_speed + 100
			if coyote > 0:
				coyote -= delta
		velocity.x = lerp(velocity.x,dir*side_speed,delta*accel)
		if round(dir) != 0:
			$SideHitbox.scale.x = round(dir)
	elif knocked_time > 0:
		if !is_on_floor():
			if (velocity + get_gravity()*delta).y < max_fall_speed:
				velocity += get_gravity()*delta

func _input(event: InputEvent) -> void:
	if event.device == Main.controllers[player_num-1]:
		if knocked_time <= 0 and taunt_time_left <= 0 and life > 0:
			if event.is_action_pressed("Jump") and event.device == controller and !freefall:
				jump()
			if cooldown_time <= 0:
				if event.is_action_pressed('Taunt') and event.device == controller and !freefall:
					taunt()
				if event.is_action_pressed("Special") and event.device == controller and !freefall and cooldown_time <= 0:
					special_attack(event)

func special_attack(event):
	var dir = Vector2(Input.get_joy_axis(controller,JOY_AXIS_LEFT_X),Input.get_joy_axis(controller,JOY_AXIS_LEFT_Y))
	if dir.length() > dead_zone:
		if abs(dir.x)-0.3 > abs(dir.y): #side
			can_move = false
			var objective
			var original_pos : Vector2 = global_position
			for area in $SideHitbox.get_overlapping_areas():
				if area != $Hurtbox:
					objective = area.get_parent()
					break
			if objective == null:
				cooldown_time = swing_fail_punishment
				await get_tree().create_timer(swing_fail_punishment,false).timeout
				can_move = true
			else:
				cooldown_time = 0.3
				var swing_direction = sign(dir.x)
				var final_pos = -40*swing_direction
				var swing_speed = 0.001
				while abs(global_position.x+final_pos-objective.global_position.x) > 10 and objective != null:
					objective.global_position.x = lerp(objective.global_position.x,global_position.x+final_pos,swing_speed)
					objective.global_position.y = global_position.y
					velocity.y = 0
					global_position = original_pos
					swing_speed *= get_process_delta_time()*100
					await get_tree().process_frame
				can_move = true
				if objective != null:
					objective.hurt(
						swing_damage,
						Vector2(-swing_direction,-0.5).normalized(),
						swing_strength
					)
		elif dir.y < 0: #upper
			velocity.y = -up_tentacle_power
			freefall = true
			await get_tree().create_timer(up_tentacle_windup,false).timeout
			for area in $UpperHitbox.get_overlapping_areas():
				if area != $Hurtbox:
					freefall = false
					area.get_parent().hurt(
						up_tentacle_damage,
						Vector2(0,1),
						up_tentacle_strength
					)
			velocity.y = -up_tentacle_jump
		elif dir.y > 0: #down
			freefall = true
			velocity.y = -slam_power
			await get_tree().create_timer(0.2,false).timeout
			velocity.y = slam_speed
			while freefall:
				for area in $DownHitbox.get_overlapping_areas():
					if area != $Hurtbox:
						reboot()
						area.get_parent().hurt(
							slam_damage,
							Vector2(0,1),
							slam_strength
							)
						velocity.y = -slam_power
						freefall = false
						$DownParticles.emitting = true
					await get_tree().process_frame
	else: #neutral
		if note_child == null:
			var instance : CharacterBody2D = note.instantiate()
			instance.global_position = global_position
			add_child(instance)
			instance.get_node('Timer').start(note_lifetime)
			note_child = instance
		else:
			global_position = note_child.global_position
			note_child.destroy()
			

func reboot():
	jumps_left = num_of_extra_jumps
	coyote = coyote_max_time
	freefall = false
	can_move = true
	cooldown_time = 0

func taunt():
	taunt_time_left = taunt_time
	$TauntSFX.play(0)
	cooldown_time += taunt_cooldown
	$Taunt.rotation = deg_to_rad(randf_range(0,360))
	$Taunt.show()
	await get_tree().create_timer(taunt_time,false).timeout
	$Taunt.hide()
func jump():
	if is_on_floor() or coyote > 0 or jumps_left > 0:
		if !is_on_floor() and coyote <= 0:
			jumps_left -= 1
		coyote = 0
		var time_on_air : float = 0
		while Input.is_action_pressed("Jump") and time_on_air < jump_max_height:
			time_on_air += 1
			velocity.y = -jump_force
			await get_tree().physics_frame

func _on_collision_checker_body_entered(body: Node2D) -> void:
	if body.is_in_group('map') and velocity.y >= 0:
		reboot()
