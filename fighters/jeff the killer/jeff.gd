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

@export_category('Side')
@export var dive_damage : float
@export var dive_strength : float
@export var dive_power : float
@export var dive_jump_power : float

@export_category('Down')
@export var dog_max_damage : float
@export var dog_min_damage : float
@export var dog_max_strength : float
@export var dog_min_strength : float
@export var dog_max_time : float
@export var dog_time_cap : float

@export_category('Neutral')
@export var slice_damage : float
@export var slice_strength : float

@export_category('Upper')
@export var uppercut_damage : float
@export var uppercut_strength : float
@export var uppercut_power : float

var jumps_left : int = 0
var player_num : int
var has_started : bool
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
			$SideHitbox.scale.x = sign(dir)
			$DownHitbox.scale.x = sign(dir)
			$NeutralHitbox.scale.x = sign(dir)
			$UpperHitbox.scale.x = sign(dir)
	elif knocked_time > 0:
		if !is_on_floor():
			if (velocity + get_gravity()*delta).y < max_fall_speed:
				velocity += get_gravity()*delta

func _input(event: InputEvent) -> void:
	if event.device == controller and has_started:
		if knocked_time <= 0 and taunt_time_left <= 0 and life > 0:
			if event.is_action_pressed("Jump") and !freefall:
				jump()
			if cooldown_time <= 0:
				if event.is_action_pressed('Taunt'):
					taunt()
			if event.is_action_pressed("Special") and !freefall and cooldown_time <= 0:
					special_attack(event)

func special_attack(event: InputEvent):
	var dir = Vector2(Input.get_joy_axis(controller,JOY_AXIS_LEFT_X),Input.get_joy_axis(controller,JOY_AXIS_LEFT_Y))
	if dir.length() > dead_zone:
		if abs(dir.x)-0.3 > abs(dir.y): #side
			freefall = true
			velocity.y = -dive_jump_power
			while freefall and velocity.y < 0:
				for area in $SideHitbox.get_overlapping_areas():
					if area != $Hurtbox:
						area.get_parent().hurt(
							dive_damage,
							Vector2(randf_range(-1,1),-1).normalized(),
							dive_strength
						)
						freefall = false
						jumps_left = 1
						cooldown_time = 0.1
						return
				await get_tree().process_frame
		elif dir.y < 0: #upper
			velocity.y = -uppercut_power
			freefall = true
			var people_hit : Array = []
			while velocity.y < 0:
				for area in $UpperHitbox.get_overlapping_areas():
					if area != $Hurtbox and area not in people_hit:
						people_hit.append(area)
						area.get_parent().hurt(
							uppercut_damage,
							Vector2(sign(area.global_position.x-global_position.x),-2).normalized(),
							uppercut_strength
						)
				await get_tree().process_frame
		elif dir.y > 0: #down
			var time_left = dog_time_cap
			while time_left > 0 and (Input.is_joy_button_pressed(controller,JOY_BUTTON_B) or Input.is_joy_button_pressed(controller,JOY_BUTTON_X)):
				time_left -= get_process_delta_time()
				can_move = false
				await get_tree().process_frame
			can_move = true
			var time_spent = min(dog_time_cap - time_left,dog_max_time)
			for area in $DownHitbox.get_overlapping_areas():
				if area != $Hurtbox:
					area.get_parent().hurt(
						remap(time_spent,0,dog_max_time,dog_min_damage,dog_max_damage),
						Vector2($DownHitbox.scale.x,-1).normalized(),
						remap(time_spent,0,dog_max_time,dog_min_strength,dog_max_strength)
						)
			
	else: #neutral
		var slice_direction = Vector2(randf_range(-1,1),-1).normalized()
		for area in $NeutralHitbox.get_overlapping_areas():
			if area != $Hurtbox:
				area.get_parent().hurt(
					slice_damage,
					slice_direction,
					slice_strength
				)
		velocity = slice_direction * slice_strength*10
		cooldown_time += 0.1
		


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
