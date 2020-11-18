extends Area2D


func _ready():
	pass

func _on_DrivePlumePhysics_body_entered(body):
	if "type" in body:
		if body.type == "Fragment" or body.type == "Asteroid":
			body.apply_impulse(Vector2(),Vector2(-20000,rand_range(-100,100)))
