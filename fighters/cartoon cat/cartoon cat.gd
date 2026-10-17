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

@export_category('Neutral')
@export var baseball : PackedScene
@export var ball_speed : float
@export var bat_range : float
@export var bat_speed : float
@export var home_run_range : float
@export var home_run_speed : float
@export var bat_damage : float = 10
@export var bat_strength : float = 150

@export_category('Upper')
@export var helicopter_damage : float
@export var helicopter_strength : float
@export var helicopter_time : float
@export var helicopter_max_speed : float
@export var helicopter_accel : float
var helicopter_time_left : float = 0

@export_category('Side')
@export var charging_time : float
@export var charge_damage : float
@export var charge_launch : float
@export var charge_speed : float
var charge_time_left : float = 0

@export_category('Down')
@export var tail_windup : float
@export var tail_damage : float
@export var tail_strength : float
@export var tail_power : float

var jumps_left : int = 0
var player_num : int
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
	knocked_time = strength * remap(life,0,max_life,0.02,0.0005)
	if charge_time_left <= 0:
		reboot()

func hurt(damage:float, dir:Vector2, strength:float):
	if charge_time_left <= 0:
		reboot()
	hit_taken.emit(damage, dir, strength)
	if strength > weight:
		weight = 0
		launch(dir,strength)
		can_move = true
	life -= damage
	$Label.text = str(life)
	if life <= 0:
		die(dir)

func die(dir : Vector2 = Vector2.ZERO):
	dead.emit(self)
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
		if charge_time_left <= 0:
			reboot()

func manage_movement(delta):
	if knocked_time <= 0 and taunt_time_left <= 0:
		leap()
		var dir : float = 0
		if abs(Input.get_joy_axis(controller,JOY_AXIS_LEFT_X)) > dead_zone and can_move:
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
			$NeutralHitbox.scale.x = round(dir)
			if charge_time_left <= 0:
				$SideHitbox.scale.x = round(dir)
	elif knocked_time > 0:
		if !is_on_floor():
			if (velocity + get_gravity()*delta).y < max_fall_speed:
				velocity += get_gravity()*delta

func _input(event: InputEvent) -> void:
	if knocked_time <= 0 and taunt_time_left <= 0 and life > 0:
		if event.is_action_pressed("Jump") and event.device == controller and !freefall and helicopter_time_left <= 0:
			jump()
		if cooldown_time <= 0 and can_move and helicopter_time_left <= 0 and charge_time_left <= 0:
			if event.is_action_pressed('Taunt') and event.device == controller:
				taunt()
			if event.is_action_pressed("Special") and event.device == controller and !freefall and helicopter_time_left <= 0 and charge_time_left <= 0:
				special_attack(event)

func special_attack(event: InputEvent):
	var dir = Vector2(Input.get_joy_axis(controller,JOY_AXIS_LEFT_X),Input.get_joy_axis(controller,JOY_AXIS_LEFT_Y))
	if dir.length() > dead_zone:
		if abs(dir.x)-0.3 > abs(dir.y): #side
			var direction = sign(dir.x)
			$Charge.direction.x = -direction
			emit_particles($Charge,global_position+Vector2(20*direction,18))
			$SideHitbox.monitoring = true
			charge_time_left = charging_time
			jumps_left = 0
			if velocity.y > 0:
				velocity.y = 0
			while charge_time_left > 0:
				charge_time_left -= get_process_delta_time()
				velocity.x = charge_speed*direction
				for area in $SideHitbox.get_overlapping_areas():
					if area != $Hurtbox:
						area.get_parent().hurt(
							charge_damage,
							Vector2(sign(velocity.x)*2,-1).normalized(),
							charge_launch
							)
						charge_time_left = 0
				await get_tree().process_frame
				
		elif dir.y < 0: #upper
			if is_on_floor():
				velocity.y = -200
				await get_tree().process_frame
			helicopter_time_left = helicopter_time
			while helicopter_time_left > 0 and !is_on_floor():
				if Input.is_joy_button_pressed(event.device,JOY_BUTTON_X) or Input.is_joy_button_pressed(event.device,JOY_BUTTON_B):
					helicopter_time_left -= get_process_delta_time()
					fly()
					if !$Helicopter.emitting:
						$Helicopter.emitting = true
				else:
					if $Helicopter.emitting:
						$Helicopter.emitting = false
				await get_tree().process_frame
			$Helicopter.emitting = false
			if !is_on_floor():
				freefall = true
		elif dir.y > 0: #down
			velocity.y = -tail_power
			freefall = true
			await get_tree().create_timer(tail_windup,false).timeout
		
			for area in $DownHitbox.get_overlapping_areas():
				if area != $Hurtbox:
					area.get_parent().hurt(
						tail_damage,
						Vector2(0,-1),
						tail_strength
					)
			freefall = false
	else: #neutral
		var ball
		weight = 300
		can_move = false
		playback.travel('Neutral')
		if !has_node("Baseball"):
			ball = spawn_ball()
		while Input.is_joy_button_pressed(event.device,JOY_BUTTON_X) or Input.is_joy_button_pressed(event.device,JOY_BUTTON_B):
			await get_tree().process_frame
		if weight <= 0:
			return
		if ball != null:
			if round(abs(global_position.y - ball.global_position.y)) < bat_range:
				if round(abs(global_position.y - ball.global_position.y)) < home_run_range:
					print('HOME RUN!')
					ball.linear_velocity = Vector2(sign(global_position.direction_to(ball.global_position).x) * home_run_speed,0)
					ball.global_position.y = global_position.y
					ball.hit(true)
				else:
					print('ball hit!')
					ball.linear_velocity = global_position.direction_to(ball.global_position) * bat_speed
					ball.hit(false)
		while playback.get_current_node() == 'Neutral' and playback.get_current_play_position() < 0.5:
			await get_tree().process_frame
		playback.travel('Neutral_end')
		weight = 0
		can_move = true
		
func spawn_ball() -> RigidBody2D:
	var ball : RigidBody2D = baseball.instantiate()
	ball.global_position = $NeutralHitbox/Neutral.global_position
	ball.linear_velocity.y = ball_speed
	add_child(ball)
	return ball

func fly():
	if velocity.y > -helicopter_max_speed:
		velocity.y -= helicopter_accel
		for area in $UpperHitbox.get_overlapping_areas():
			if area != $Hurtbox:
				area.get_parent().hurt(
					helicopter_damage,
					Vector2.UP+Vector2(randf_range(0.5,-0.5),0),
					helicopter_strength
				)
func reboot():
	jumps_left = num_of_extra_jumps
	coyote = coyote_max_time
	freefall = false
	helicopter_time_left = 0
	


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
	if body.is_in_group('map') and charge_time_left <= 0:
		reboot()

func emit_particles(node,pos):
	var particles = node.duplicate()
	particles.global_position = pos
	particles.connect('finished',particles.queue_free)
	add_child(particles)
	particles.emitting = true

func bat_hit() -> void:
	if $NeutralHitbox.get_overlapping_areas() != []:
			for area in $NeutralHitbox.get_overlapping_areas():
				if area != $Hurtbox:
					area.get_parent().hurt(bat_damage,
					Vector2(sign(area.global_position.x-global_position.x),0)+Vector2(0,-0.3),
					bat_strength)
