extends TextureRect

const HIDDEN_MAGNIFY_POSITION := -1*Vector2.ONE

export var disabled := true

var _screen_size := Vector2.ZERO
var _enabled := true
var _camera_panning := false
var _last_magnify_position := -1*Vector2.ONE

#signal camera_pan_started()
#signal camera_pan_stopped()



func _ready():
	SignalMgr.register_subscriber(self, "zoom_step_change_initiated", "_on_zoom_step_change_initiated")
#	SignalMgr.register_subscriber(self, "camera_pan_started" ,"_on_camera_pan_started")
#	SignalMgr.register_subscriber(self, "camera_pan_stopped" ,"_on_camera_pan_stopped")
	SignalMgr.register_subscriber(self, "update_magnify_position", "_on_update_magnify_position")
	SignalMgr.register_subscriber(self, "hide_magnify", "_on_hide_magnify")
	_screen_size = OS.window_size;
	material.set_shader_param("aspect_ratios", _screen_size.y / _screen_size.x);
	material.set_shader_param("mag_pos", -1*Vector2.ONE);

#func _input(event):
#	if (event is InputEventMouseMotion):
#		var p = get_viewport().get_mouse_position()
#		var norm_mouse = p / screen_size;
#		norm_mouse.y = 1.0 - norm_mouse.y;
#		material.set_shader_param("mouse_pos", norm_mouse);

func _on_update_magnify_position(screen_position: Vector2, tile_map_world_position: Vector2, tile_map_cell: Vector2) -> void:
	if disabled:
		return
	if !_enabled && !_camera_panning:
		return
	var norm_position = screen_position / _screen_size
	norm_position.y = 1.0 - norm_position.y
	if norm_position == _last_magnify_position:
		return
	_last_magnify_position = norm_position
	material.set_shader_param("mag_pos", norm_position)


func _on_zoom_step_change_initiated(from_zoom_step: int, to_zoom_step: int, zoom_speed: float) -> void:
	_enabled = to_zoom_step == 2
	if !_enabled:
		material.set_shader_param("mag_pos", HIDDEN_MAGNIFY_POSITION)
		_last_magnify_position = HIDDEN_MAGNIFY_POSITION


#func _on_camera_pan_started():
#	if disabled:
#		return
#	_camera_panning = true
#	material.set_shader_param("mag_pos", HIDDEN_MAGNIFY_POSITION)
#
#
#func _on_camera_pan_stopped():
#	_camera_panning = false
#	#_on_update_magnify_position(_last_magnify_position)

func _on_hide_magnify():
	if disabled:
		return
	material.set_shader_param("mag_pos", HIDDEN_MAGNIFY_POSITION)
