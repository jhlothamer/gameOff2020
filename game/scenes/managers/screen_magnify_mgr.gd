extends Node2D

signal update_magnify_position(screen_position, tile_map_world_position, tile_map_cell)
signal hide_magnify()

#const HIDDEN_MAGNIFY_POSITION := -100*Vector2.ONE

var _enabled := true
var _camera_panning := false
var _magnify_area_rect := Rect2(Vector2.ZERO, Vector2.ZERO)
var _magnify_area_rect_initialized := false

func _ready():
	SignalMgr.register_subscriber(self, "zoom_step_change_initiated", "_on_zoom_step_change_initiated")
	SignalMgr.register_subscriber(self, "structure_state_changed", "_on_structure_state_changed")
	SignalMgr.register_publisher(self, "update_magnify_position")
	SignalMgr.register_publisher(self, "hide_magnify")
#	SignalMgr.register_subscriber(self, "camera_pan_started" ,"_on_camera_pan_started")
#	SignalMgr.register_subscriber(self, "camera_pan_stopped" ,"_on_camera_pan_stopped")

func _input(event):
	if !_enabled || _camera_panning:
		return
	if (event is InputEventMouseMotion):
		var p = get_viewport().get_mouse_position()
		var global_mouse_position = get_global_mouse_position()
		var structure_tile_map := Game.get_structure_tiles_tile_map()
		var mouse_map_position = structure_tile_map.world_to_map(global_mouse_position)
		if !_magnify_area_rect_initialized:
			_update_mag_rect()
		if _magnify_area_rect.has_point(mouse_map_position):
			var world_position = structure_tile_map.map_to_world(mouse_map_position) + structure_tile_map.cell_size/2.0
			emit_signal("update_magnify_position", p, world_position, mouse_map_position)
#			var norm_mouse = p / _screen_size;
#			norm_mouse.y = 1.0 - norm_mouse.y;
#			material.set_shader_param("mouse_pos", norm_mouse);
		else:
			#emit_signal("update_magnify_position", HIDDEN_MAGNIFY_POSITION)
			emit_signal("hide_magnify")


func _on_zoom_step_change_initiated(from_zoom_step: int, to_zoom_step: int, zoom_speed: float) -> void:
	_enabled = to_zoom_step == 2


func _on_camera_pan_started():
	_camera_panning = true
	#material.set_shader_param("mag_pos", HIDDEN_MAGNIFY_POSITION)


func _on_camera_pan_stopped():
	_camera_panning = false

func _update_mag_rect() -> void:
	var structure_tile_map := Game.get_structure_tiles_tile_map()
	_magnify_area_rect = _get_used_area(structure_tile_map)


func _get_used_area(t: TileMap) -> Rect2:
	if t == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var used_cells = t.get_used_cells()
	if used_cells.size() == 0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	_magnify_area_rect_initialized = true
	var area := Rect2(used_cells[0], Vector2.ZERO)
	for used_cell in used_cells:
		area = area.expand(used_cell)
	area = area.expand(area.end + Vector2.ONE)
	return area
		
func on_structure_state_changed(cellv):
	_update_mag_rect()
