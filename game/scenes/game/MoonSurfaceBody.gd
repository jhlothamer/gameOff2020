extends StaticBody2D

func _ready():
	var extents = get_parent().radius
	scale = Vector2(extents/10, extents/10)


