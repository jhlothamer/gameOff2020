extends Node
class_name CameraZoom2D


export var zoom_speed = .25
export var min_camera_zoom: float = .25
export var max_camera_zoom: float = 10.0
export var initial_camera_zoom: float = .25


onready var camera: Camera2D = get_parent() if typeof(get_parent()) == typeof(Camera2D) else null

func _ready():
	if camera == null:
		return
	camera.zoom = Vector2.ONE * clamp(initial_camera_zoom, min_camera_zoom, max_camera_zoom)


func _input(event):
	if !event is InputEventMouseButton || camera == null:
		return
	var delta = 0
	if event.button_index == BUTTON_WHEEL_DOWN:
		delta = zoom_speed
	if event.button_index == BUTTON_WHEEL_UP:
		delta = -zoom_speed
	
	var zoom = camera.zoom.x
	zoom = clamp( zoom + delta, min_camera_zoom, max_camera_zoom)
	camera.zoom = Vector2(zoom, zoom)
