extends Area2D

signal asteroid_impact()

func _ready():
	var extents = get_parent().radius
	scale = Vector2(extents/10, extents/10)
	SignalMgr.register_publisher(self, "asteroid_impact")


func _body_impacted(body):
	if "type" in body:
		if body.type == "Asteroid":
			var spawn_mgr = Globals.get("SpawnMgr")
			emit_signal("asteroid_impact")
			spawn_mgr._asteroid_impact(body)
		else:
			# other types of collsions?
			pass

func _on_MoonSurfaceCollision_body_entered(body):
	_body_impacted(body)

func _on_DriveSurface_body_entered(body):
	_body_impacted(body)
