extends StaticBody2D

func _ready():
	var extents = get_parent().get_node("MoonBackground").radius
	scale = Vector2(extents/10, extents/10)


