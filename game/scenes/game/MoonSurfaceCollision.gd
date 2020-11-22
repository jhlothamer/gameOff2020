extends Area2D

signal asteroid_impact()
signal CameraShake()

func _ready():
	var extents = get_parent().radius
	scale = Vector2(extents/10, extents/10)
	SignalMgr.register_publisher(self, "asteroid_impact")
	SignalMgr.register_publisher(self, "CameraShake")


func _body_impacted(body):
	if "type" in body:
		if body.type == "Asteroid":
			var spawn_mgr = Globals.get("SpawnMgr")
			emit_signal("asteroid_impact")
			var duration = 1
			var intensity = 30
			if "impact_force" in body:
				duration = body.impact_force / 30
				intensity = body.impact_force
			duration += rand_range( -1.5, 1.5 )
			intensity += rand_range(-20, 20)
			intensity = clamp(intensity, 10, 100)
			duration = clamp(duration, 0.5, 5)
			emit_signal("CameraShake", 1.0, duration, intensity )
			spawn_mgr._asteroid_impact(body)
		else:
			# other types of collsions?
			pass

func _on_MoonSurfaceCollision_body_entered(body):
	_body_impacted(body)

func _on_DriveSurface_body_entered(body):
	_body_impacted(body)
