extends Node
class_name CameraZoom2D

signal zoom_step_change_initiated(from_zoom_step, to_zoom_step, zoom_speed)


export var zoom_speed = .25
export var min_camera_zoom: float = .25
export var max_camera_zoom: float = 10.0
export var initial_camera_zoom: float = .25
export var zoom_steps: int = 0
export var zoom_step_time_seconds := .2
export var zoom_to_mouse := false

onready var camera: Camera2D = get_parent() if typeof(get_parent()) == typeof(Camera2D) else null
onready var tween: Tween

var _current_zoom_step := 0
var _window_size := Vector2.ZERO

func _ready():
	if camera == null:
		return
	SignalMgr.register_publisher(self, "zoom_step_change_initiated")
	camera.zoom = Vector2.ONE * clamp(initial_camera_zoom, min_camera_zoom, max_camera_zoom)
	_current_zoom_step = zoom_steps
	tween = Tween.new()
	add_child(tween)
	_window_size.x = ProjectSettings.get_setting("display/window/size/width")
	_window_size.y = ProjectSettings.get_setting("display/window/size/height")

func _unhandled_input(event):
	#func _input(event):
	if !event is InputEventMouseButton || camera == null:
		return
	if event.button_index != BUTTON_WHEEL_UP and event.button_index != BUTTON_WHEEL_DOWN:
		return
	var zoom_in := false
	if event.button_index == BUTTON_WHEEL_DOWN:
		zoom_in = false
	if event.button_index == BUTTON_WHEEL_UP:
		zoom_in = true
	if zoom_steps < 1:
		_zoom_regular(zoom_in)
	else:
		_zoom_step(zoom_in)


func _zoom_regular(zoom_in: bool) -> void:
	var delta = 0
	if zoom_in:
		delta = -zoom_speed
	else:
		delta = zoom_speed
	
	var zoom = camera.zoom.x
	zoom = clamp( zoom + delta, min_camera_zoom, max_camera_zoom)

	if zoom_to_mouse:
		var mouse_pos = _get_real_mouse_position()
		var point = mouse_pos
		var c0 = camera.global_position
		var v0 = get_viewport().size
		var z0 = camera.zoom
		var z1 = zoom*Vector2.ONE
		
		var c1 = c0 + (-0.5*v0 + point)*(z0-z1)
		camera.global_position = c1

	camera.zoom = Vector2(zoom, zoom)



func _zoom_step(zoom_in: bool) -> void:
	if tween.is_active():
		return
	var zoom_change = (max_camera_zoom - min_camera_zoom) / float(zoom_steps)
	if zoom_in:
		zoom_change *= -1.0
	
	var zoom =camera.zoom.x
	zoom = clamp(zoom + zoom_change, min_camera_zoom, max_camera_zoom)
	if zoom == camera.zoom.x:
		return
	
	#var x = (zoom - min_camera_zoom) / (max_camera_zoom - min_camera_zoom)*zoom_steps
	var current_zoom_level = (camera.zoom.x - min_camera_zoom) / float(abs(zoom_change))
	var next_zoom_level = current_zoom_level + 1
	if zoom_in:
		next_zoom_level = current_zoom_level - 1
	emit_signal("zoom_step_change_initiated", current_zoom_level, next_zoom_level, zoom_step_time_seconds)
	
	tween.interpolate_property(camera, "zoom", camera.zoom, Vector2.ONE*zoom, zoom_step_time_seconds,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	if zoom_to_mouse and zoom_in:
		var mouse_pos = _get_real_mouse_position()
				
		var point = mouse_pos
		var c0 = camera.global_position
		var v0 = get_viewport().size
		print("viewport size is " + str(v0))
		var z0 = camera.zoom
		var z1 = zoom*Vector2.ONE

		var c1 = c0 + (-0.5*v0 + point)*(z0-z1)
		tween.interpolate_property(camera, "global_position", camera.global_position, c1, zoom_step_time_seconds,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		#tween.interpolate_property(camera, "global_position", camera.global_position, mouse_pos, zoom_step_time_seconds,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _get_real_mouse_position() -> Vector2:
	var viewport := get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var scaling = viewport.size / _window_size
	mouse_pos *= scaling
	
	return mouse_pos

