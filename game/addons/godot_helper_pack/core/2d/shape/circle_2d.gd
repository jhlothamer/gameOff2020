tool
class_name Circle2D
extends Position2D

export (float, .1, 10000.0) var radius: float = 10.0 setget set_radius
export var color: Color = Color.white setget set_color
export var stroke := false setget set_stroke
export var stroke_color := Color.black setget set_stroke_color
export (float, 1.0, 20.0) var stroke_width := 2.0 setget set_stroke_width
export (int, 10, 10000) var point_count := 200 setget set_point_count

func set_color(value):
	color = value
	update()

func set_radius(value):
	radius = value
	update()

func set_stroke(value):
	stroke = value
	update()

func set_stroke_color(value):
	stroke_color = value
	update()

func set_stroke_width(value):
	stroke_width = value
	update()

func set_point_count(value):
	point_count = value
	update()

func _draw():
	draw_circle(Vector2.ZERO, radius, color)
	if stroke:
		draw_arc(Vector2.ZERO, radius - (stroke_width/2.0), 0.0, 2*PI, point_count,
			stroke_color, stroke_width, true)
#	else:
#		draw_arc(Vector2.ZERO, radius - 1, 0.0, 2*PI, 200, color, 2, true)
