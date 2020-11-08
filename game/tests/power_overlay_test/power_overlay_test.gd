extends Node2D

signal toggle_power_overlay(show_overlay)
signal update_power_overlay()


func _ready():
	SignalMgr.register_publisher(self, "toggle_power_overlay")
	SignalMgr.register_publisher(self, "update_power_overlay")
	call_deferred("_test")


func _test():
	emit_signal("toggle_power_overlay", true)
