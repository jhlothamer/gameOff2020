extends Area2D

onready var spawn_mgr = get_parent().get_node("SpawnerMgr")

func _ready():
	var extents = get_parent().get_node("MoonBackground").radius
	scale = Vector2(extents/10, extents/10)


func _body_impacted(body):
	if "type" in body:
		if body.type == "Asteroid":
			spawn_mgr._asteroid_impact(body)
		else:
			# other types of collsions?
			pass

func _on_MoonSurfaceCollision_body_entered(body):
	_body_impacted(body)

func _on_DriveSurface_body_entered(body):
	_body_impacted(body)