class_name StructureMgr
extends Node

const structure_data_file_path = "res://assets/data/structures.json"

class StructureData:
	var structure_type_id :int = Constants.StructureTileType.UUC
	var tile_map_cell := Vector2.ZERO
	#if not a power station or UUC then list of power stations that power this cell
	var power_stations := []
	#if a power station then what cells it powers
	var powers_cells := []
	#total amount of power being used from powered cells or amount of power being given to a non-power station structure
	var power_subscription := 0
	var structure_meta_data
	var disabled := false
	var resources_lacking := []
	var current_animation
	func _init(structure_type_id_: int, tile_map_cell_: Vector2, structure_meta_data_):
		structure_type_id = structure_type_id_
		tile_map_cell = tile_map_cell_
		structure_meta_data = structure_meta_data_
	func power_station_process_structure(structure: StructureData):
		var required_power = structure.structure_meta_data["operatingResources"]["electricity"]
		if required_power == 0:
			return
		required_power -= structure.power_subscription
		if required_power == 0:
			return
		var power_provided = structure_meta_data["powerProvided"]
		var power_left = power_provided - power_subscription
		if power_left == 0:
			return
		if power_left >= required_power:
			structure.power_subscription += required_power
			power_subscription += required_power
		else:
			structure.power_subscription += power_left
			power_subscription += power_left
	func update_lack_resources():
		resources_lacking.clear()
		if structure_type_id != Constants.StructureTileType.Power:
			#check power
			var required_power = structure_meta_data["operatingResources"]["electricity"]
			if power_subscription < required_power:
				resources_lacking.append("electricity")
				print("structure at tile " + str(tile_map_cell) + " lacks power")
		#check population
	func clear_current_animation():
		if current_animation == null:
			return
		current_animation.queue_free()
		current_animation = null


export var allowed_tiles_tile_map: NodePath
export var structure_tiles_tile_map: NodePath
export var structure_status_overlay_tiles_tile_map: NodePath
#ConstructionRepairEtcAnimations
export var construction_repair_etc_animations_parent: NodePath

var _allowed_tiles_tile_map: TileMap
var _structure_tiles_tile_map: TileMap
var _structure_status_overlay_tiles_tile_map: TileMap
var _construction_repair_etc_animations_parent: Node2D
var _construction_animation_class = preload("res://scenes/animations/ConstructionAnimation.tscn")

# metadata about structures
var _structure_data := {}
# map of structure name to id
var _structure_name_to_id := {}
# map of structure id to name
var _structure_id_to_name := {}

# map of tile map cell to structure data
var _structures := {}

var _spiral_vectors := []
var _power_radius_tiles_sq: float

var _structure_alert_status_overlay_tile_id := {}
var _structure_disable_status_overlay_tile_id := {}


func _ready():
	#SignalMgr.register_subscriber(self, "structure_tile_placed", "_on_structure_tile_placed")
	Globals.set("StructureMgr", self)
	_spiral_vectors = GraphUtil.spiral_vectors(200)

	if structure_tiles_tile_map != null:
		_structure_tiles_tile_map = get_node_or_null(structure_tiles_tile_map)
	if allowed_tiles_tile_map != null:
		_allowed_tiles_tile_map = get_node_or_null(allowed_tiles_tile_map)
	if structure_status_overlay_tiles_tile_map != null:
		_structure_status_overlay_tiles_tile_map = get_node_or_null(structure_status_overlay_tiles_tile_map)
	if construction_repair_etc_animations_parent != null:
		_construction_repair_etc_animations_parent = get_node_or_null(construction_repair_etc_animations_parent)
	
	
	var structure_file: File = File.new()
	var error = structure_file.open(structure_data_file_path, File.READ)
	if error != OK:
		print("error opening structure data file")
		structure_file.close()
		return
	var json_text = structure_file.get_as_text()
	var parse_results:JSONParseResult =  JSON.parse(json_text)
	if parse_results.error != OK:
		print("error parsing structure data.")
		print(parse_results.error_string)
		print(parse_results.error_line)
		return
	_structure_data = parse_results.result
	structure_file.close()
	
	_structure_name_to_id = _structure_data["ids"]
	for structure_name in _structure_name_to_id.keys():
		_structure_id_to_name[int(_structure_name_to_id[structure_name])] = structure_name
	
	for structure_type_id in _structure_id_to_name.keys():
		_structure_alert_status_overlay_tile_id[structure_type_id] = Constants.STRUCTURE_TILE_TYPE_COUNT + structure_type_id
		_structure_disable_status_overlay_tile_id[structure_type_id] = Constants.STRUCTURE_TILE_TYPE_COUNT*2 + structure_type_id
	
	_init_structures_list()
	


func _init_structures_list():
	if _structure_tiles_tile_map == null:
		return
	var power_structure = _get_structure_metadata_by_id(Constants.StructureTileType.Power)
	var power_radius = power_structure["powerRadius"]
	var cell_size = _structure_tiles_tile_map.cell_size
	_power_radius_tiles_sq = cell_size.x * cell_size.x * float(power_radius) * float(power_radius)
	
	var used_cells = _structure_tiles_tile_map.get_used_cells()
	for used_cell in used_cells:
		var tile_id = _structure_tiles_tile_map.get_cellv(used_cell)
		_structures[used_cell] = _create_structure_data_object(tile_id, used_cell)
	
	refresh_structure_resources()
	

func _create_structure_data_object(structure_type_id: int, tile_map_cell: Vector2, disabled: bool = false) -> StructureData:
	var structure_meta_data = _get_structure_metadata_by_id(structure_type_id)
	var structureData = StructureData.new(structure_type_id, tile_map_cell, structure_meta_data)
	structureData.disabled = disabled
	if structure_type_id == Constants.StructureTileType.Power:
		structureData.powers_cells = _get_powered_cells(tile_map_cell)
	return structureData


func add_structure(structure_tile_type: int, cell_v: Vector2) -> void:
	var structure = _create_structure_data_object(structure_tile_type, cell_v, true)
	_structures[cell_v] = structure
	_structure_tiles_tile_map.set_cellv(structure.tile_map_cell, structure.structure_type_id)
	_structure_status_overlay_tiles_tile_map.set_cellv(structure.tile_map_cell, _structure_disable_status_overlay_tile_id[structure.structure_type_id])
	_do_construction_animation(structure)

func remove_structure(cell_v: Vector2) -> void:
	if !_structures.has(cell_v):
		return
	var structure: StructureData = _structures[cell_v]
	if !structure.disabled:
		structure.disabled = true
		refresh_structure_resources()
	_structures.erase(cell_v)
	if structure.structure_type_id  != Constants.StructureTileType.UUC:
		_structures[cell_v] = _create_structure_data_object(Constants.StructureTileType.UUC, cell_v, false)
		_structure_tiles_tile_map.set_cellv(cell_v, Constants.StructureTileType.UUC)
	else:
		_structure_tiles_tile_map.set_cellv(cell_v, -1)
	_do_reclamation_animation(structure)
	


func refresh_structure_resources():
	var power_stations = []
	for structure in _structures.values():
		structure.power_subscription = 0
		if structure.structure_type_id == Constants.StructureTileType.Power && !structure.disabled:
			power_stations.append(structure)

	_structure_status_overlay_tiles_tile_map.clear()
	
	for power_station in power_stations:
		for powered_cell in power_station.powers_cells:
			if powered_cell == power_station.tile_map_cell:
				continue
			if !_structures.has(powered_cell):
				continue
			var structure = _structures[powered_cell]
			power_station.power_station_process_structure(structure)
	
	for structure in _structures.values():
		structure.update_lack_resources()
		if structure.disabled:
			_structure_status_overlay_tiles_tile_map.set_cellv(structure.tile_map_cell, _structure_disable_status_overlay_tile_id[structure.structure_type_id])
		elif structure.resources_lacking.size() > 0:
			_structure_status_overlay_tiles_tile_map.set_cellv(structure.tile_map_cell, _structure_alert_status_overlay_tile_id[structure.structure_type_id])
		else:
			_structure_status_overlay_tiles_tile_map.set_cellv(structure.tile_map_cell, -1)



func _get_powered_cells(power_station_cell: Vector2) -> Array:
	var cell_size: Vector2 =  _structure_tiles_tile_map.cell_size
	var half_cell_size: Vector2 = cell_size*.5
	
	var power_station_cell_mid_pt: Vector2 = power_station_cell*cell_size + half_cell_size
	var powered_cells := []
	var current_cell: Vector2 = power_station_cell
	for spiral_vector in _spiral_vectors:
		current_cell = power_station_cell + spiral_vector
		if _allowed_tiles_tile_map.get_cellv(current_cell) == -1:
			continue
		var current_cell_mid_pt = current_cell*cell_size + half_cell_size
		var d_sq = current_cell_mid_pt.distance_squared_to(power_station_cell_mid_pt)
		if d_sq > _power_radius_tiles_sq:
			continue
		powered_cells.append(current_cell)
	
	return powered_cells

func _get_structure_metadata_by_id(structure_type_id: int) -> Dictionary:
	var structure_type_name = _structure_id_to_name[structure_type_id]
	return _structure_data["structures"][structure_type_name]

func get_structure_construction_resources(structure_type_id: int) -> Dictionary:
	var structure_metadata = _get_structure_metadata_by_id(structure_type_id)
	
	return structure_metadata["constructionResources"]


func _do_construction_animation(structure: StructureData) -> void:
	var construction_animation: AnimatedSprite = _construction_animation_class.instance()
	structure.current_animation = construction_animation
	_construction_repair_etc_animations_parent.add_child(construction_animation)
	construction_animation.global_position = _structure_tiles_tile_map.map_to_world(structure.tile_map_cell)
	construction_animation.play("default")
	yield(construction_animation, "animation_finished")
	construction_animation.queue_free()
	structure.disabled = false
	refresh_structure_resources()

func _do_reclamation_animation(structure: StructureData) -> void:
	structure.clear_current_animation()
	var construction_animation: AnimatedSprite = _construction_animation_class.instance()
	structure.current_animation = construction_animation
	_construction_repair_etc_animations_parent.add_child(construction_animation)
	construction_animation.global_position = _structure_tiles_tile_map.map_to_world(structure.tile_map_cell)
	construction_animation.play("default", true)
	yield(construction_animation, "animation_finished")
	construction_animation.queue_free()
	#structure.disabled = false
	#_structure_tiles_tile_map.set_cellv(structure.tile_map_cell, -1)
	refresh_structure_resources()



func is_disabled(tile_map_cell: Vector2) -> bool:
	if _structures.has(tile_map_cell):
		var structure: StructureData = _structures[tile_map_cell]
		return structure.disabled
	return true
