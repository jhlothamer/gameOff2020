extends Node

export var power_radius_tiles := 4

export var placement_overlay_tile_map: NodePath
export var allowed_tiles_tile_map: NodePath
export var structure_tiles_tile_map: NodePath
export var power_overlay_tile_map: NodePath

onready var _placement_overlay_tile_map: TileMap = get_node_or_null(placement_overlay_tile_map) if placement_overlay_tile_map != null else null
onready var _allowed_tiles_tile_map: TileMap = get_node_or_null(allowed_tiles_tile_map) if allowed_tiles_tile_map != null else null
onready var _structure_tiles_tile_map: TileMap = get_node_or_null(structure_tiles_tile_map) if structure_tiles_tile_map != null else null
onready var _power_overlay_tile_map: TileMap = get_node_or_null(power_overlay_tile_map) if power_overlay_tile_map != null else null

var _power_radius_tiles_sq: float

var _spiral_vectors := []

func _ready():
	SignalMgr.register_subscriber(self, "toggle_power_overlay", "_on_toggle_power_overlay")
	SignalMgr.register_subscriber(self, "update_power_overlay", "_on_update_power_overlay")
	
	if _power_overlay_tile_map != null:
		var cell_size = _power_overlay_tile_map.cell_size
		_power_radius_tiles_sq = cell_size.x * cell_size.x * float(power_radius_tiles) * float(power_radius_tiles)
	
	_spiral_vectors = GraphUtil.spiral_vectors(200)


func _on_toggle_power_overlay(show):
	if !show:
		_power_overlay_tile_map.clear()
		return
	_on_update_power_overlay()


func _on_update_power_overlay():
	_power_overlay_tile_map.clear()
	var power_station_cells = _get_power_station_cells()
	for power_station_cell in power_station_cells:
		var powered_cells = _get_powered_cells(power_station_cell)
		for powered_cell in powered_cells:
			var tile_id = _power_overlay_tile_map.get_cellv(powered_cell)
			if tile_id == -1:
				_power_overlay_tile_map.set_cellv(powered_cell, 0)
			elif tile_id == 0:
				_power_overlay_tile_map.set_cellv(powered_cell, 1)
			else:
				_power_overlay_tile_map.set_cellv(powered_cell, 2)


func _get_power_station_cells():
	var power_station_cells
	
	power_station_cells = _structure_tiles_tile_map.get_used_cells_by_id(Constants.StructureTileType.Power)
	ArrayUtil.append_all(power_station_cells, _placement_overlay_tile_map.get_used_cells_by_id(Constants.StructureTileType.Power))
	#ArrayUtil.append_all(power_station_cells, _placement_overlay_tile_map.get_used_cells_by_id(Constants.StructureTileType.Power + Constants.STRUCTURE_TILE_TYPE_COUNT))
	
	return power_station_cells


func _get_powered_cells(power_station_cell: Vector2) -> Array:
	var cell_size: Vector2 =  _power_overlay_tile_map.cell_size
	var half_cell_size: Vector2 = cell_size*.5
	
	var power_station_cell_mid_pt: Vector2 = power_station_cell*cell_size + half_cell_size
	var powered_cells := []
	var current_cell: Vector2 = power_station_cell
	for spiral_vector in _spiral_vectors:
		current_cell = power_station_cell + spiral_vector
#		powered_cells.append(current_cell)
#		continue
		if _allowed_tiles_tile_map.get_cellv(current_cell) == -1:
			continue
		var current_cell_mid_pt = current_cell*cell_size + half_cell_size
		var d_sq = current_cell_mid_pt.distance_squared_to(power_station_cell_mid_pt)
		if d_sq > _power_radius_tiles_sq:
			continue
		powered_cells.append(current_cell)
	
	return powered_cells



