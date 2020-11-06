extends CanvasLayer

signal focused_gained(control)

var _last_control_focused: Control

func _ready():
	SignalMgr.register_publisher(self, "focused_gained")



func _unhandled_input(event):
	if event is InputEventMouseButton:
		print("unhandled mouse button event")
		emit_signal("focused_gained", self)
