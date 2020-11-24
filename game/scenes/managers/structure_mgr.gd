class_name StructureMgr
extends Node

const structure_data_file_path = "res://assets/data/structures.json"

enum StructureTileType {
	UUC,
	Power,
	Agriculture,
	Residential,
	Office,
	Education,
	Medical,
	Reclamation,
	Factory,
	Recreation
}

class StructureMetadata:
	var structure_metadata
	func _init(metadata: Dictionary):
		structure_metadata = metadata
	func _get_metadata_item(item_name: String) -> Dictionary:
		if structure_metadata == null || !structure_metadata.has(item_name):
			return {}
		return structure_metadata[item_name]
	func get_construction_resources() -> Dictionary:
		return _get_metadata_item("constructionResources")
	func get_repair_resources() -> Dictionary:
		return _get_metadata_item("repairResources")
	func get_reclamation_resources() -> Dictionary:
		return _get_metadata_item("reclamationResources")
	func get_name():
		return structure_metadata["name"]
	

class StructureData:
	var structure_type_id :int = Constants.StructureTileType.UUC
	var tile_map_cell := Vector2.ZERO
	#if not a power station or UUC then list of power stations that power this cell
	var power_stations := []
	#if a power station then what cells it powers
	var powers_cells := []
	#total amount of power being used from powered cells or amount of power being given to a non-power station structure
	var power_subscription := 0
	var structure_metadata
	var disabled := false
	var damaged := false
	var structure_name = ""
	var under_construction := true
	var resources_lacking := []
	var current_animation
	func _init(structure_type_id_: int, tile_map_cell_: Vector2, structure_metadata_):
		structure_type_id = structure_type_id_
		tile_map_cell = tile_map_cell_
		structure_metadata = structure_metadata_
	func power_station_process_structure(structure: StructureData):
		if structure.disabled:
			return
		var required_power = structure.structure_metadata["operatingResources"]["electricity"]
		if required_power == 0:
			return
		required_power -= structure.power_subscription
		if required_power == 0:
			return
		var power_provided = structure_metadata["powerProvided"]
		var power_left = power_provided - power_subscription
		if power_left == 0:
			return
		if power_left >= required_power:
			structure.power_subscription += required_power
			power_subscription += required_power
		else:
			structure.power_subscription += power_left
			power_subscription += power_left
	func _get_name():
		return structure_name
	func _set_name(new_name):
		structure_name = new_name
	func update_lack_resources():
		resources_lacking.clear()
		if structure_type_id != Constants.StructureTileType.Power:
			#check power
			var required_power = structure_metadata["operatingResources"]["electricity"]
			if power_subscription < required_power:
				resources_lacking.append("electricity")
				#print("structure at tile " + str(tile_map_cell) + " lacks power")
		#check population
	func clear_current_animation():
		if current_animation == null:
			return
		current_animation.queue_free()
		current_animation = null
	func set_damaged(is_damaged:bool) -> void:
		damaged = is_damaged
		disabled = is_damaged
	func lacks_resources() -> bool:
		return resources_lacking.size() > 0
		

var _construction_animation_class = preload("res://scenes/animations/ConstructionAnimation.tscn")
var _repair_animation_class = preload("res://scenes/animations/RepairAnimation.tscn")
var _structure_interaction_temp_sound_class := preload("res://scenes/sound/structure_interaction_temp_sound.tscn")

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
const _structure_enabled_status_overlay_tile_id := Constants.STRUCTURE_TILE_TYPE_COUNT*3
const _structure_lack_resource_status_overlay_tile_id := Constants.STRUCTURE_TILE_TYPE_COUNT*3 + 1

func _ready():
	Globals.set("StructureMgr", self)
	_spiral_vectors = GraphUtil.spiral_vectors(200)

	_structure_data = FileUtil.load_json_data(structure_data_file_path)
	
	_structure_name_to_id = _structure_data["ids"]
	for structure_name in _structure_name_to_id.keys():
		_structure_id_to_name[int(_structure_name_to_id[structure_name])] = structure_name
	
	for structure_type_id in _structure_id_to_name.keys():
		_structure_alert_status_overlay_tile_id[structure_type_id] = Constants.STRUCTURE_TILE_TYPE_COUNT + structure_type_id
		_structure_disable_status_overlay_tile_id[structure_type_id] = Constants.STRUCTURE_TILE_TYPE_COUNT*2 + structure_type_id
	
	call_deferred("_init_structures_list")


static func get_structure_mgr() -> StructureMgr:
	return Globals.get("StructureMgr")


func _init_structures_list():
	if Game.get_structure_tiles_tile_map() == null:
		return
	var power_structure = _get_structure_metadata_by_id(Constants.StructureTileType.Power)
	var power_radius = power_structure["powerRadius"]
	var cell_size = Game.get_structure_tiles_tile_map().cell_size
	_power_radius_tiles_sq = cell_size.x * cell_size.x * float(power_radius) * float(power_radius)
	
	var used_cells = Game.get_structure_tiles_tile_map().get_used_cells()
	for used_cell in used_cells:
		var tile_id = Game.get_structure_tiles_tile_map().get_cellv(used_cell)
		var structure = _create_structure_data_object(tile_id, used_cell)
		structure.under_construction = false
		_structures[used_cell] = structure
		#_separator_boxes_tile_map.set_cellv(used_cell, _structure_enabled_status_overlay_tile_id)
	
	refresh_structure_resources()
	

func _create_structure_data_object(structure_type_id: int, tile_map_cell: Vector2, disabled: bool = false, custom_name: String = "") -> StructureData:
	var structure_metadata = _get_structure_metadata_by_id(structure_type_id)
	var structureData = StructureData.new(structure_type_id, tile_map_cell, structure_metadata)
	structureData.disabled = disabled
	if structure_type_id == Constants.StructureTileType.Power:
		structureData.powers_cells = _get_powered_cells(tile_map_cell)
	if custom_name == "":
		if _structure_id_to_name.has(structure_type_id):
			structureData.structure_name = _structure_id_to_name[structure_type_id]
		else:
			print("error structure base id " + str(structure_type_id) + " has no name")
	else:
		structureData.structure_name = custom_name
	return structureData


func add_structure(structure_tile_type: int, cell_v: Vector2) -> void:
	var structure = _create_structure_data_object(structure_tile_type, cell_v, true)
	_structures[cell_v] = structure
	Game.get_structure_tiles_tile_map().set_cellv(structure.tile_map_cell, structure.structure_type_id)
	Game.get_structure_status_overlay_tiles_tile_map().set_cellv(structure.tile_map_cell, _structure_disable_status_overlay_tile_id[structure.structure_type_id])
	_do_construction_animation(structure)

func get_damagable_structures() -> Array:
	var damagable_structures := []
	for structure in _structures.values():
		if structure.damaged || structure.under_construction:
			continue
		damagable_structures.append(structure)
	return damagable_structures

func remove_structure(cell_v: Vector2) -> void:
	if !_structures.has(cell_v):
		return
	var structure: StructureData = _structures[cell_v]
	if !structure.disabled:
		structure.disabled = true
		refresh_structure_resources()
	_do_reclamation_animation(structure)
	

func repair_structure(cell_v: Vector2) -> void:
	if !_structures.has(cell_v):
		return
	var structure: StructureData = _structures[cell_v]
	if structure.disabled || structure.damaged:
		#refresh_structure_resources()
		_do_repair_animation(structure)



func refresh_structure_resources(debug: bool = false):
	var power_stations = []
	for structure in _structures.values():
		structure.power_subscription = 0
		if structure.structure_type_id == Constants.StructureTileType.Power && !structure.disabled:
			power_stations.append(structure)

	Game.get_structure_status_overlay_tiles_tile_map().clear()
	
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
			Game.get_structure_status_overlay_tiles_tile_map().set_cellv(structure.tile_map_cell, _structure_disable_status_overlay_tile_id[structure.structure_type_id])
			Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, _structure_lack_resource_status_overlay_tile_id)
		elif structure.resources_lacking.size() > 0:
			#_structure_status_overlay_tiles_tile_map.set_cellv(structure.tile_map_cell, _structure_alert_status_overlay_tile_id[structure.structure_type_id])
			Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, _structure_lack_resource_status_overlay_tile_id)
		elif structure.under_construction:
			Game.get_structure_status_overlay_tiles_tile_map().set_cellv(structure.tile_map_cell, _structure_disable_status_overlay_tile_id[structure.structure_type_id])
			Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, -1)
		else:
			Game.get_structure_status_overlay_tiles_tile_map().set_cellv(structure.tile_map_cell, -1)
			Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, _structure_enabled_status_overlay_tile_id)
		
		_refresh_structure_resource_indicators(structure)
		
		if structure.damaged:
			Game.get_damage_overlay_tile_map().set_cellv(structure.tile_map_cell, 0)
			Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, _structure_lack_resource_status_overlay_tile_id)
		else:
			if debug:
				print("clearing damage overlat for tile at " + str(structure.tile_map_cell))
			Game.get_damage_overlay_tile_map().set_cellv(structure.tile_map_cell, -1)
			#_separator_boxes_tile_map.set_cellv(structure.tile_map_cell, _structure_enabled_status_overlay_tile_id)


func _refresh_structure_resource_indicators(structure: StructureData):
	if structure.structure_type_id == Constants.StructureTileType.UUC:
		return
		
	var structure_resource_icon_cellv = structure.tile_map_cell * 8 + Vector2(5,6)
	
	if structure.structure_type_id != Constants.StructureTileType.Power:
		if structure.resources_lacking.has("electricity"):
			Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 2)
		else:
			Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 0)
	
	structure_resource_icon_cellv += Vector2.RIGHT
	
	if structure.resources_lacking.has("population"):
		Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 3)
	else:
		Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 1)


func _get_powered_cells(power_station_cell: Vector2) -> Array:
	var cell_size: Vector2 =  Game.get_structure_tiles_tile_map().cell_size
	var half_cell_size: Vector2 = cell_size*.5
	
	var power_station_cell_mid_pt: Vector2 = power_station_cell*cell_size + half_cell_size
	var powered_cells := []
	var current_cell: Vector2 = power_station_cell
	for spiral_vector in _spiral_vectors:
		current_cell = power_station_cell + spiral_vector
		if Game.get_allowed_tiles_tile_map().get_cellv(current_cell) == -1:
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


func get_structure_metadata(structure_type_id: int) -> StructureMetadata:
	return StructureMetadata.new(_get_structure_metadata_by_id(structure_type_id))

	
func _do_construction_animation(structure: StructureData) -> void:
	var interaction_sound = _structure_interaction_temp_sound_class.instance()
	Game.get_construction_repair_etc_animations_parent().add_child(interaction_sound)
	interaction_sound.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
	interaction_sound.play_placement_sound()
	yield(interaction_sound, "tree_exited")
	Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, -1)
	var construction_animation: AnimatedSprite = _construction_animation_class.instance()
	structure.current_animation = construction_animation
	Game.get_construction_repair_etc_animations_parent().add_child(construction_animation)
	construction_animation.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
	construction_animation.play_construction_animation()
	yield(construction_animation, "animation_finished")
	construction_animation.queue_free()
	structure.disabled = false
	structure.under_construction = false
	#_separator_boxes_tile_map.set_cellv(structure.tile_map_cell, _structure_enabled_status_overlay_tile_id)
	refresh_structure_resources()

func _do_reclamation_animation(structure: StructureData) -> void:
	structure.clear_current_animation()
	Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, -1)
	var construction_animation: AnimatedSprite = _construction_animation_class.instance()
	structure.current_animation = construction_animation
	Game.get_construction_repair_etc_animations_parent().add_child(construction_animation)
	construction_animation.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
	construction_animation.play_reclamation_animation()
	yield(construction_animation, "animation_finished")
	construction_animation.queue_free()
	_structures.erase(structure.tile_map_cell)
	Game.get_structure_tiles_tile_map().set_cellv(structure.tile_map_cell, -1)
	if structure.structure_type_id != Constants.StructureTileType.UUC:
		#_separator_boxes_tile_map.set_cellv(structure.tile_map_cell, _structure_enabled_status_overlay_tile_id)
		var uuc_structure = _create_structure_data_object(Constants.StructureTileType.UUC, structure.tile_map_cell, false)
		uuc_structure.under_construction = false
		_structures[structure.tile_map_cell] = uuc_structure
		Game.get_structure_tiles_tile_map().set_cellv(structure.tile_map_cell, Constants.StructureTileType.UUC)
	refresh_structure_resources()


func _do_repair_animation(structure: StructureData) -> void:
	#_separator_boxes_tile_map.set_cellv(structure.tile_map_cell, -1)
	var repair_animation: AnimatedSprite = _repair_animation_class.instance()
	structure.current_animation = repair_animation
	Game.get_construction_repair_etc_animations_parent().add_child(repair_animation)
	repair_animation.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
	repair_animation.play("default")
	yield(repair_animation, "repair_complete")
	structure.disabled = false
	structure.damaged = false
	print("done repairing tile at " + str(structure.tile_map_cell))
	repair_animation.queue_free()
	structure.disabled = false
	#_separator_boxes_tile_map.set_cellv(structure.tile_map_cell, _structure_enabled_status_overlay_tile_id)
	refresh_structure_resources(true)

func is_disabled(tile_map_cell: Vector2) -> bool:
	if _structures.has(tile_map_cell):
		var structure: StructureData = _structures[tile_map_cell]
		return structure.disabled
	return true

func get_structure_by_mouse_global_position() -> StructureData:
	var global_position: Vector2 = Game.get_structure_tiles_tile_map().get_global_mouse_position()
	var tile_map_cell = Game.get_structure_tiles_tile_map().world_to_map(global_position)
	if !_structures.has(tile_map_cell):
		return null
	return _structures[tile_map_cell]

func disable_structure(cell_v: Vector2):
	if !_structures.has(cell_v):
		return
	var structure: StructureData = _structures[cell_v]
	if !structure.disabled:
		structure.disabled = true
		refresh_structure_resources()
		var interaction_sound = _structure_interaction_temp_sound_class.instance()
		Game.get_construction_repair_etc_animations_parent().add_child(interaction_sound)
		interaction_sound.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
		interaction_sound.play_player_deactivate_sound()
		
	
func enable_structure(cell_v: Vector2):
	if !_structures.has(cell_v):
		return
	var structure: StructureData = _structures[cell_v]
	if structure.disabled:
		structure.disabled = false
		refresh_structure_resources()
		var interaction_sound = _structure_interaction_temp_sound_class.instance()
		Game.get_construction_repair_etc_animations_parent().add_child(interaction_sound)
		interaction_sound.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
		interaction_sound.play_player_reactive_sound()

func damage_structure(structure: StructureData):
	structure.set_damaged(true)
	refresh_structure_resources()
	var interaction_sound = _structure_interaction_temp_sound_class.instance()
	Game.get_construction_repair_etc_animations_parent().add_child(interaction_sound)
	interaction_sound.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
	interaction_sound.play_failure_deactive_sound()

func get_functioning_structures_by_type_name(type_name: String) -> Array:
	var structure_type_id = EnumUtil.get_id(Constants.StructureTileType, type_name)
	var functioning_structures := []
	for structure in _structures.values():
		if structure.structure_type_id != structure_type_id:
			continue
		if structure.disabled or structure.damaged or structure.under_construction or structure.lacks_resources():
			continue
		functioning_structures.append(structure)
	return functioning_structures

	
