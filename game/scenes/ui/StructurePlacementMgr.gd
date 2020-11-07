extends Node2D

signal structure_tile_placed(structure_tile_type, cell_v)

export var placement_overlay_tile_map: NodePath
export var allowed_tiles_tile_map: NodePath
export var structure_tiles_tile_map: NodePath


onready var _placement_overlay_tile_map: TileMap = get_node_or_null(placement_overlay_tile_map) if placement_overlay_tile_map != null else null
onready var _allowed_tiles_tile_map: TileMap = get_node_or_null(allowed_tiles_tile_map) if allowed_tiles_tile_map != null else null
onready var _structure_tiles_tile_map: TileMap = get_node_or_null(structure_tiles_tile_map) if structure_tiles_tile_map != null else null

var _placing_structure := false
var _allowed_placement_tiles := []
var _structure_type = Constants.StructureTileType.UUC
var _directions := [
	Vector2.LEFT,
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN
]

var _allowed_placement_tile_id = Constants.STRUCTURE_TILE_TYPE_COUNT * 2
var _disallowed_placement_tile_id = Constants.STRUCTURE_TILE_TYPE_COUNT * 2 + 1
var _last_mouse_cell_v

func _ready():
	SignalMgr.register_subscriber(self, "construction_tool_bar_clicked", "_on_construction_tool_bar_clicked")
	SignalMgr.register_publisher(self, "structure_tile_placed")


func _process(delta):
	if !_placing_structure || !_have_tile_map_nodes():
		return
	var mouse_position = get_global_mouse_position()
	var cell_v = _placement_overlay_tile_map.world_to_map(mouse_position)
	if cell_v != _last_mouse_cell_v:
		if _last_mouse_cell_v != null:
			if _allowed_placement_tiles.has(_last_mouse_cell_v):
				_placement_overlay_tile_map.set_cellv(_last_mouse_cell_v, _allowed_placement_tile_id)
			else:
				_placement_overlay_tile_map.set_cellv(_last_mouse_cell_v, -1)
		if _allowed_placement_tiles.has(cell_v):
			_placement_overlay_tile_map.set_cellv(cell_v, _structure_type)
		else:
			_placement_overlay_tile_map.set_cellv(cell_v, _structure_type + Constants.STRUCTURE_TILE_TYPE_COUNT)
		_last_mouse_cell_v = cell_v
	
	

func _on_construction_tool_bar_clicked(structure_type):
	if !_have_tile_map_nodes():
		return
	_allowed_placement_tiles = _get_allowed_placement_tiles(structure_type)
	if _allowed_placement_tiles == null or _allowed_placement_tiles.size() < 1:
		return
	for allowed_placement_tile in _allowed_placement_tiles:
		_placement_overlay_tile_map.set_cellv(allowed_placement_tile, _allowed_placement_tile_id)
	_structure_type = structure_type
	_placing_structure = true


func _have_tile_map_nodes():
	return _placement_overlay_tile_map != null and _allowed_tiles_tile_map != null and _structure_tiles_tile_map != null


func _get_allowed_placement_tiles(structure_type):
	if structure_type != Constants.StructureTileType.UUC:
		return _structure_tiles_tile_map.get_used_cells_by_id(Constants.StructureTileType.UUC)
	
	var allowed_placement_tiles = []
	var placed_structure_cells = _structure_tiles_tile_map.get_used_cells()
	for placed_structure_cell in placed_structure_cells:
		for direction in _directions:
			var potential_structure_cell = placed_structure_cell + direction
			if _structure_tiles_tile_map.get_cellv(potential_structure_cell) != -1:
				continue
			if !_allowed_tiles_tile_map.get_cellv(potential_structure_cell) != -1:
				continue
			allowed_placement_tiles.append(potential_structure_cell)
	
	return allowed_placement_tiles

func _input(event):
	#return
	if !_placing_structure or !event is InputEventMouseButton:
		return
	var mouse_button_event:InputEventMouseButton = event
	if mouse_button_event.button_index == BUTTON_LEFT:
		if _last_mouse_cell_v != null:
			if _allowed_placement_tiles.has(_last_mouse_cell_v):
				_structure_tiles_tile_map.set_cellv(_last_mouse_cell_v, _structure_type)
				emit_signal("structure_tile_placed", _structure_type, _last_mouse_cell_v)
		_placing_structure = false
		_allowed_placement_tiles = []
		_last_mouse_cell_v = null
		_placement_overlay_tile_map.clear()



