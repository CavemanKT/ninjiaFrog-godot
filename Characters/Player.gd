extends Character

export(float) var move_speed = 150
export(float) var jump_impulse = 500
export(float) var enemy_bounce_impulse = 400
export(float) var knockback_collision_speed = 75
export(float) var wall_slide_friction = 0.5
export(int) var max_jumps = 2
export(float) var jump_damage = 1
export(bool) var facing_right = true
enum STATE {IDLE, RUN, JUMP, DOUBLE_JUMP, FALL, WALL_SLIDE, HIT}

onready var animated_sprite = $AnimatedSprite
onready var animation_tree = $AnimationTree
onready var jump_hitbox = $JumpHitBox
onready var invincible_timer = $InvincibleTimer
onready var wall_jump_timer = $WallJumpTimer
onready var drop_timer = $DropTimer
signal changed_state(new_state_str, new_state_id)

var velocity : Vector2

var current_state = STATE.IDLE setget set_current_state # does this mean every time current_state is assigned a new value, set_current_state has to run itself.
var jumps = 0
var wall_jump_direction: Vector2
var is_boarding_wall = false

func _physics_process(delta):
	var input = get_player_input()
	
	if(Input.is_action_just_pressed("down")):
		if(drop_timer.is_stopped()):
			drop_timer.start()
		else:
			drop()

	velocity = move_and_slide(velocity, Vector2.UP)    # after the collision, the the set of velocity will be zero.
	is_boarding_wall = get_is_on_wall_raycast_test()
	set_anim_parameters()
	
	match(current_state):
		STATE.IDLE, STATE.RUN, STATE.JUMP, STATE.DOUBLE_JUMP, STATE.FALL:
			if(wall_jump_timer.is_stopped()):
				velocity = normal_move(input)
			else:
				velocity = wall_jumping_movement()
			pick_next_state()
		STATE.HIT:
			velocity = hit_move()
		STATE.WALL_SLIDE:
			velocity = wall_slide_move()
			pick_next_state()
			
func normal_move(input):
	adjust_flip_direction(input)
	return Vector2(
		input.x * move_speed,
		min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)  
	)

func hit_move():
	var knockback_direction : Vector2

	#if AngryPid facing right, knock player to right
	if(animated_sprite.flip_h):
		knockback_direction = Vector2.RIGHT
	else:
	#if AngryPid facing left, knock player to left
		knockback_direction = Vector2.LEFT
	return Vector2(knockback_collision_speed * knockback_direction.x, 0)

func wall_slide_move():
	return Vector2(
		velocity.x,
		min(velocity.y + (GameSettings.gravity * wall_slide_friction), GameSettings.terminal_velocity)
	)

func wall_jumping_movement():
	return Vector2(
		move_speed * wall_jump_direction.x,
		min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
	)

func adjust_flip_direction(input: Vector2):
	if(sign(input.x) == 1):
		animated_sprite.flip_h = !facing_right
	elif(sign(input.x) == -1):
		animated_sprite.flip_h = facing_right

func set_anim_parameters():
	animation_tree.set("parameters/x_sign/blend_position", sign(velocity.x))
	animation_tree.set("parameters/y_sign/blend_amount", sign(velocity.y))
	var is_on_wall_int: int
	if(is_boarding_wall):
		is_on_wall_int = 1
	else:
		is_on_wall_int = 0
	animation_tree.set('parameters/is_on_wall/blend_amount', is_on_wall_int)


func pick_next_state():
	if(is_on_floor()):
		jumps = 0
		if(Input.is_action_just_pressed('jump')):
			self.current_state = STATE.JUMP
		elif(abs(velocity.x) > 0):
			self.current_state = STATE.RUN
		else:
			self.current_state = STATE.IDLE
	elif(Input.is_action_just_pressed('jump') && jumps < max_jumps):
		if(is_boarding_wall):
			self.current_state = STATE.JUMP
		else:
			if(jumps == 0):
				jumps = 1
			self.current_state = STATE.DOUBLE_JUMP
		
	elif(is_boarding_wall):
		self.current_state = STATE.WALL_SLIDE
	else:
		self.current_state = STATE.FALL

	
func get_player_input():
	var input : Vector2
	
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	return input
	
	
#flip the direction of the animated sprite
func get_facing_direction():
	if(animated_sprite.flip_h == false):
		return Vector2.RIGHT
	else:
		return Vector2.LEFT
	
func get_is_on_wall_raycast_test():
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, global_position + 10 * get_facing_direction(), [self], self.collision_mask)
	if(result.size() > 0):
		return true
	else:
		return false
	
func jump():
	velocity.y = -jump_impulse
	jumps += 1
	
func wall_jump():
	velocity.y = -jump_impulse
	jumps = 1
	wall_jump_direction = -get_facing_direction()
	wall_jump_timer.start()

func drop():
	position.y += 1

func _on_JumpHitBox_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	var enemy = area.owner

	if(enemy is Enemy && enemy.can_be_hit):
		# Check to see if we are hitting the enemy at the right position and velocity
		# if(jump_hitbox.global_position.y <= area.global_position.y + 1 && velocity.y > 0)  
		if(velocity.y > 0):
			print("jump hb : " + str(jump_hitbox.global_position))
			print("body Pos : " + str(area.global_position))
			velocity.y = -enemy_bounce_impulse
			
			enemy.get_hit(jump_damage)
		
		
func get_hit(damage: float):
	if(invincible_timer.is_stopped()):
		self.health -= damage
		self.current_state = STATE.HIT
		invincible_timer.start()
	
func die():
	emit_signal("player_died", self)
	queue_free()
	
func on_hit_finished():
	self.current_state = STATE.IDLE

# SETTERS
func set_current_state(new_state):
	match(new_state):
		STATE.JUMP:
			if(current_state == STATE.WALL_SLIDE):
				if(Input.is_action_just_pressed("jump")):
					wall_jump()
			else:
				jump()
		STATE.DOUBLE_JUMP:
			jump()
			animation_tree.set('parameters/double_jump/active', true)
		STATE.HIT:
			animation_tree.set('parameters/hit/active', true)
		STATE.WALL_SLIDE:
			jumps = 0
			
	current_state = new_state
	emit_signal("changed_state", STATE.keys()[new_state], new_state)
	



