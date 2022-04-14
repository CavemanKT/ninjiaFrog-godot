extends Character

class_name Enemy 

export(bool) var can_be_hit = true  
export(float) var collision_damage = 1

func _on_EnemyCollisionHitBox_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	body.get_hit(collision_damage)
	
