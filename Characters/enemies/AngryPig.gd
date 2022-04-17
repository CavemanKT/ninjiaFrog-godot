extends Enemy

enum STATE {IDLE, RUN, WALK, HIT}

export(float) var walk_speed = 75
export(float) var run_speed = 180



var current_state = STATE.WALK


func _physics_process(delta):
	waypoint_move(delta)
			
func _get_move_velocity(delta, direction):
	# Move towards waypoint
	var direction_x_sign = sign(direction.x)
	
	var move_speed : float
	
	match(current_state):
		STATE.WALK:
			move_speed = walk_speed
		STATE.RUN:
			move_speed = run_speed
	#move towards waypoint
	return Vector2(
		move_speed * sign(direction.x),
		min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
	)
	
func _get_distance_to_waypoint(waypoint_position: Vector2):
	return Vector2(self.position.x, 0).distance_to(Vector2(waypoint_position.x, 0)) 

func _on_AngryDectionZone_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	animation_tree.set('parameters/player_detected/blend_position', 1)
	if(current_state == STATE.WALK):
		current_state = STATE.RUN

func _on_AngryDectionZone_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	animation_tree.set('parameters/player_detected/blend_position', 0)
	if(current_state == STATE.RUN):
		current_state = STATE.WALK


func get_hit(damage: float):
	self.health -= damage

	can_be_hit = false
	current_state = STATE.HIT
	var anim_selection = GameSettings.RandGen.randi_range(0, 1)
	
	animation_tree.set('parameters/hit/active', true)
	animation_tree.set('parameters/hit_variation/blend_amount', anim_selection)

func _hit_animation_finish():
	can_be_hit = true
	current_state = STATE.RUN


