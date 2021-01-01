tool
extends "res://scenes/game/moon_interface.gd"


onready var _line2d := $Impossible_Drive/Line2D

var _line2d_length := 1.0

func _ready():
	_set_drive_on(drive_on)
	_line2d_length = abs(_line2d.points[1].x - _line2d.points[0].x)

func _enter_tree():
	ServiceMgr.register_service(Moon, self)


func _set_drive_on(value):
	drive_on = value
	if _line2d == null:
		return
	_line2d.visible = drive_on


func _set_exhaust_length_percent(value):
	exhaust_length_percent = value
	if _line2d == null:
		return
	var new_length = value * _line2d_length
	_line2d.points[1].x = _line2d.points[0].x - new_length
