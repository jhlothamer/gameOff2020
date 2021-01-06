class_name Moon

extends "res://addons/godot_helper_pack/core/2d/shape/circle_2d.gd"

export var drive_on := true setget _set_drive_on
export (float, 0.0, 1.0) var exhaust_length_percent := 1.0 setget _set_exhaust_length_percent

func _set_drive_on(value):
	pass

func _set_exhaust_length_percent(value):
	pass
