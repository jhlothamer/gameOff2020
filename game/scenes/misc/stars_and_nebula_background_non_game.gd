tool
extends TextureRect

export var speed := 1.0 setget _set_speed


func _ready():
	_set_speed(speed)


func _set_speed(value):
	speed = value
	var shader_material: ShaderMaterial = material
	shader_material.set_shader_param("speed", value)

