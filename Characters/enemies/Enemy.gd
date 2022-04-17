extends Character

class_name Enemy 

export(float) var waypoint_arrived_distance = 10
var facing_right = true

export(Array, NodePath) var waypoints
export(int) var starting_waypoint = 0

onready var waypoint_position = get_node(waypoints[starting_waypoint]).position
onready var waypoint_index = starting_waypoint setget set_waypoint_index
var velocity : Vector2 = Vector2.ZERO

export(bool) var can_be_hit = true  
export(float) var collision_damage = 1

onready var animated_sprite = $AnimatedSprite
onready var animation_tree = $AnimationTree


func waypoint_move(delta):
	var direction = self.position.direction_to(waypoint_position)   
	# direction contains the info of magnitude and direction
	var distance = _get_distance_to_waypoint(waypoint_position)
#	var distance_x = Vector2(self.position.x, 0).distance_to(Vector2(waypoint_position.x, 0)) 
	
	if(distance >= waypoint_arrived_distance):
		velocity = _get_move_velocity(delta, direction)
		var direction_x_sign = sign(direction.x)
		#flip the direction 
		if(direction_x_sign > 0):
			animated_sprite.flip_h = facing_right
		else:
			animated_sprite.flip_h = !facing_right
		
		velocity = move_and_slide(velocity, Vector2.UP)
	else:
		#switch waypoint
		var num_waypoints = waypoints.size()
		if(self.waypoint_index < num_waypoints - 1):
			self.waypoint_index += 1
		else: 
			self.waypoint_index = 0
			

func _get_distance_to_waypoint(waypoint_position):
	return self.position.distance_to(waypoint_position)

func _get_move_velocity(_delta, _direction):
	printerr('Get Move Velocity has not been implemented.')


func _on_EnemyCollisionHitBox_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	body.get_hit(collision_damage)
	
# SETTER
func set_waypoint_index(value):
	waypoint_index = value
	waypoint_position = get_node(waypoints[value]).position
