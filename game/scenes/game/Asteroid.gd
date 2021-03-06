extends RigidBody2D

var type = "Asteroid"
var delayed_kick_impulse = 0
var delayed_torque_impulse = Vector2(0,0)
var physics_tick_countdown = 10
var apply_initial_force = true
var disintegration_countdown = 3
var marked_for_disintegration = false
# used for camera shake calculations
var impact_force = 30

func _ready():
	pass
	
func _physics_process(delta):
	if marked_for_disintegration:
		if disintegration_countdown <= 0:
			get_parent()._disintegrate(self)
			marked_for_disintegration = false
		else:
			disintegration_countdown -= 1
	if physics_tick_countdown <= 0 and apply_initial_force:
		_give_asteroid_kick()
		apply_initial_force = false
	else:
		if apply_initial_force:
			physics_tick_countdown -= 1

func _give_asteroid_kick():
	apply_impulse(Vector2(rand_range(-100,100),rand_range(-100,100)), delayed_kick_impulse )
	apply_torque_impulse(delayed_torque_impulse)

func _mark_for_disintegration():
	marked_for_disintegration = true

func _on_AsteroidBody_body_entered(body):
	if "type" in body:
		if body.type == "Fragment":
			get_parent()._disintegrate(self)
			get_parent().fragments.erase(body)
			body.queue_free()
		elif body.type == "Asteroid":
			get_parent()._disintegrate(self)
			get_parent()._disintegrate(body)

