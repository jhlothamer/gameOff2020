extends "res://scenes/game/game_background_interface.gd"

var _time := 0.0

func _enter_tree():
	ServiceMgr.register_service(GameBackground, self)


func _process(delta):
	_time += delta * speed
	material.set_shader_param("time", _time)
