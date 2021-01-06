extends Node2D

signal structure_tile_placed(structure_tile_type, cell_v)
signal structure_tile_reclaimed(structure_tile_type, cell_v)

export var old_build_rules := false

var _placing_structure := false
var _reclaiming_structure := false
var _allowed_placement_tiles := []
var _structure_type = StructureMgr.StructureTileType.UUC
var _directions := [
	Vector2.LEFT,
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN
]

var _allowed_placement_tile_id = Constants.STRUCTURE_TILE_TYPE_COUNT * 2
var _disallowed_placement_tile_id = Constants.STRUCTURE_TILE_TYPE_COUNT * 2 + 1
var _allowed_reclaim_tile_id = Constants.STRUCTURE_TILE_TYPE_COUNT * 2 + 2
var _disallowed_reclaim_tile_id = Constants.STRUCTURE_TILE_TYPE_COUNT * 2 + 3
var _last_mouse_cell_v

func _ready():
	SignalMgr.register_subscriber(self, "construction_tool_bar_clicked", "_on_construction_tool_bar_clicked")
	SignalMgr.register_subscriber(self, "reclaim_structure_initiated", "_on_reclaim_structure_initiated")
	SignalMgr.register_publisher(self, "structure_tile_placed")
	SignalMgr.register_publisher(self, "structure_tile_reclaimed")
	

func _process(_delta):
	if !_placing_structure || !_have_tile_map_nodes():
		return
	var mouse_position = get_global_mouse_position()
	var cell_v = Game.get_placement_overlay_tile_map().world_to_map(mouse_position)
	if cell_v != _last_mouse_cell_v:
		if _last_mouse_cell_v != null:
			if _allowed_placement_tiles.has(_last_mouse_cell_v):
				Game.get_placement_overlay_tile_map().set_cellv(_last_mouse_cell_v, _allowed_placement_tile_id)
			else:
				Game.get_placement_overlay_tile_map().set_cellv(_last_mouse_cell_v, -1)
		if _allowed_placement_tiles.has(cell_v):
			if _reclaiming_structure:
				Game.get_placement_overlay_tile_map().set_cellv(cell_v, _allowed_reclaim_tile_id)
			else:
				Game.get_placement_overlay_tile_map().set_cellv(cell_v, _structure_type)
		else:
			if _reclaiming_structure:
				Game.get_placement_overlay_tile_map().set_cellv(cell_v, _disallowed_reclaim_tile_id)
			else:
				Game.get_placement_overlay_tile_map().set_cellv(cell_v, _structure_type + Constants.STRUCTURE_TILE_TYPE_COUNT)
		_last_mouse_cell_v = cell_v
	

func _on_construction_tool_bar_clicked(structure_type):
	if !_have_tile_map_nodes():
		return
	_allowed_placement_tiles = _get_allowed_placement_tiles(structure_type)
	if _allowed_placement_tiles == null or _allowed_placement_tiles.size() < 1:
		#HudAlertsMgr.add_hud_alert("No Universal Utility Conduit (UUC) tiles to build on")
		HudAlertsMgr.add_hud_alert("Build Universal Utility Conduit (UUC) tiles first")
		return
	for allowed_placement_tile in _allowed_placement_tiles:
		Game.get_placement_overlay_tile_map().set_cellv(allowed_placement_tile, _allowed_placement_tile_id)
	_structure_type = structure_type
	_placing_structure = true


func _on_reclaim_structure_initiated():
	if !_have_tile_map_nodes():
		return
	_allowed_placement_tiles = _get_allowed_reclaim_tiles()
	if _allowed_placement_tiles == null or _allowed_placement_tiles.size() < 1:
		return
	for allowed_placement_tile in _allowed_placement_tiles:
		Game.get_placement_overlay_tile_map().set_cellv(allowed_placement_tile, _allowed_placement_tile_id)
	_structure_type = -1
	_placing_structure = true
	_reclaiming_structure = true


func _have_tile_map_nodes():
	return Game.get_placement_overlay_tile_map() != null and Game.get_allowed_tiles_tile_map() != null and Game.get_structure_tiles_tile_map() != null


func _get_allowed_reclaim_tiles():
	return Game.get_structure_tiles_tile_map().get_used_cells()


func _get_allowed_placement_tiles(structure_type):
	var allowed_placement_tiles = []
	if structure_type != StructureMgr.StructureTileType.UUC:
		var uuc_cells = Game.get_structure_tiles_tile_map().get_used_cells_by_id(StructureMgr.StructureTileType.UUC)
		var enabled_uuc_cells := []
		var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
		for uuc_cell in uuc_cells:
			if !structure_mgr.is_disabled(uuc_cell):
				enabled_uuc_cells.append(uuc_cell)
		if old_build_rules:
			return enabled_uuc_cells
		else:
			allowed_placement_tiles = enabled_uuc_cells
	
	#allowed_placement_tiles = []
	var placed_structure_cells = Game.get_structure_tiles_tile_map().get_used_cells()
	for placed_structure_cell in placed_structure_cells:
		for direction in _directions:
			var potential_structure_cell = placed_structure_cell + direction
			if Game.get_structure_tiles_tile_map().get_cellv(potential_structure_cell) != -1:
				continue
			if !Game.get_allowed_tiles_tile_map().get_cellv(potential_structure_cell) != -1:
				continue
			allowed_placement_tiles.append(potential_structure_cell)
	
	return allowed_placement_tiles


func _input(event):
	if !_placing_structure or !event is InputEventMouseButton:
		return
	var mouse_button_event:InputEventMouseButton = event
	if mouse_button_event.button_index == BUTTON_LEFT:
		if _last_mouse_cell_v != null:
			if _allowed_placement_tiles.has(_last_mouse_cell_v):
				#_structure_tiles_tile_map.set_cellv(_last_mouse_cell_v, _structure_type)
				if _reclaiming_structure:
					_structure_type = Game.get_structure_tiles_tile_map().get_cellv(_last_mouse_cell_v)
					emit_signal("structure_tile_reclaimed", _structure_type, _last_mouse_cell_v)
				else:
					emit_signal("structure_tile_placed", _structure_type, _last_mouse_cell_v)
		_placing_structure = false
		_reclaiming_structure = false
		_allowed_placement_tiles = []
		_last_mouse_cell_v = null
		Game.get_placement_overlay_tile_map().clear()


