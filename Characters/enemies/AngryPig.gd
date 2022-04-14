extends Enemy


export(float) var walk_speed = 75
export(float) var run_speed = 180
export(float) var waypoint_arrived_distance = 10
export(Array, NodePath) var waypoints
export(int) var starting_waypoint = 0

enum STATE {IDLE, RUN, WALK, HIT}
var waypoint_position
var waypoint_index setget set_waypoint_index
var velocity = Vector2.ZERO
var current_state = STATE.WALK

onready var animated_sprite = $AnimatedSprite
onready var animation_tree = $AnimationTree

func _ready():
	self.waypoint_index = starting_waypoint

func _physics_process(delta):
	var direction = self.position.direction_to(waypoint_position)   
	# direction contains the info of magnitude and direction
	
	var distance_x = Vector2(self.position.x, 0).distance_to(Vector2(waypoint_position.x, 0)) 
	
#	print(distance_x, ", ", self.position.x, ", ", waypoint_position.x)
	
	if(distance_x >= waypoint_arrived_distance):
		var direction_x_sign = sign(direction.x)
		
		var move_speed : float
		
		match(current_state):
			STATE.WALK:
				move_speed = walk_speed
			STATE.RUN:
				move_speed = run_speed
		#move towards waypoint
		velocity = Vector2(
			move_speed * sign(direction.x),
			min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
		)
		
		#flip the direction 
		if(direction_x_sign > 0):
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
		
		move_and_slide(velocity, Vector2.UP)
	else:
		#switch waypoint
		var num_waypoints = waypoints.size()
		print(num_waypoints)
		if(self.waypoint_index < num_waypoints - 1):
			self.waypoint_index += 1
		else: 
			self.waypoint_index = 0
			
			
func _on_AngryDectionZone_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	animation_tree.set('parameters/player_detected/blend_position', 1)
	if(current_state == STATE.WALK):
		current_state = STATE.RUN

func _on_AngryDectionZone_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	animation_tree.set('parameters/player_detected/blend_position', 0)
	if(current_state == STATE.RUN):
		current_state = STATE.WALK


func get_hit(damage: float):
	health -= damage
	if(health <= 0):
		queue_free()
	can_be_hit = false
	current_state = STATE.HIT
	var anim_selection = GameSettings.RandGen.randi_range(0, 1)
	
	animation_tree.set('parameters/hit/active', true)
	animation_tree.set('parameters/hit_variation/blend_amount', anim_selection)

func set_waypoint_index(value):
	waypoint_index = value
	waypoint_position = get_node(waypoints[value]).position


func _hit_animation_finish():
	can_be_hit = true
	current_state = STATE.RUN
