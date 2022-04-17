extends Enemy

enum STATE { IDLE, HIT, ATTACK }

export(float) var fly_speed = 50
export(PackedScene) var projectile

var current_state = STATE.IDLE setget set_current_state

# Direction to launch the projectile
var attack_direction

# Current attack for launched projectiles
var attack_target

onready var attack_timer = $AttackTimer
onready var enemy_collision_hitbox = $EnemyCollisionHitBox
onready var launch_position = $LaunchPosition


func _physics_process(delta):
	match(current_state):
		STATE.IDLE:
			waypoint_move(delta)
			# Attack the targets that entered if the timer is not running
			if (is_instance_valid(attack_target) && attack_timer.is_stopped()):
				self.current_state = STATE.ATTACK
				attack_direction = self.position.direction_to(attack_target.position)
				print(attack_direction)
				attack_timer.start()
		STATE.ATTACK:
			waypoint_move(delta)

			
func _get_move_velocity(delta, direction):
	return fly_speed * direction

func get_hit(damage: float):
	self.health -= damage
	self.current_state = STATE.HIT

func _on_ProjectileAttackArea_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	attack_target = body

func _on_ProjectileAttackArea_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	attack_target = null

func launch_projectile(target_direction: Vector2):
	var lanuched_projectile = projectile.instance()
	lanuched_projectile.global_position = launch_position.global_position
	lanuched_projectile.rotation += target_direction.angle()
	get_tree().get_current_scene().add_child(lanuched_projectile)
	lanuched_projectile.target_direction = target_direction
	
func set_current_state(new_state):
	match(new_state):
		STATE.IDLE:
			print(current_state)						
			enemy_collision_hitbox.set_deferred("monitoring", true)
			can_be_hit = true
		STATE.ATTACK:
			print(current_state)				
			enemy_collision_hitbox.set_deferred("monitoring", true)
			can_be_hit = true
			animation_tree.set('parameters/attack/active', true)
		STATE.HIT:
			enemy_collision_hitbox.set_deferred("monitoring", false)
			can_be_hit = false
			animation_tree.set('parameters/hit/active', true)
			print('hit', current_state)						
			attack_timer.start()
	current_state = new_state

func _hit_animation_finished():
	self.current_state = STATE.IDLE
	
func _attack_animation_finished():
	self.current_state = STATE.IDLE
	launch_projectile(attack_direction)
	

