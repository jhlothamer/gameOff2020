extends Node2D

export var disabled := false

var _structure_tile_magnified_class := preload("res://scenes/animations/structure_tile_magnified.tscn")

var _enabled := true
var _current_tile_map_world_position := Vector2.INF
var _current_structure_tile_magnified


func _ready():
	SignalMgr.register_subscriber(self, "zoom_step_change_initiated", "_on_zoom_step_change_initiated")
	SignalMgr.register_subscriber(self, "update_magnify_position", "_on_update_magnify_position")
	SignalMgr.register_subscriber(self, "hide_magnify", "_on_hide_magnify")
	
	
func _on_zoom_step_change_initiated(from_zoom_step: int, to_zoom_step: int, zoom_speed: float) -> void:
	_enabled = to_zoom_step == 2


func _on_hide_magnify():
	if disabled:
		return
	_delete_all_children()
	if _current_structure_tile_magnified != null:
		_current_structure_tile_magnified = null
	_current_tile_map_world_position = Vector2.INF


func _on_update_magnify_position(_screen_position: Vector2, tile_map_world_position: Vector2, tile_map_cell: Vector2) -> void:
	if disabled:
		return
	if !_enabled:
		return
	if tile_map_cell == _current_tile_map_world_position:
		return
	_delete_all_children()
	_current_structure_tile_magnified = null
	_current_tile_map_world_position = tile_map_cell
	var structure_mgr := StructureMgr.get_structure_mgr()
	var structure = structure_mgr.get_structure_at_world_coord(tile_map_world_position)
	if structure == null:
		return
	_current_structure_tile_magnified = _structure_tile_magnified_class.instance()
	add_child(_current_structure_tile_magnified)
	_current_structure_tile_magnified.global_position = tile_map_world_position
	_current_structure_tile_magnified.structure_type_id = structure.structure_type_id

func _delete_all_children():
	for c in get_children():
		c.delete()
