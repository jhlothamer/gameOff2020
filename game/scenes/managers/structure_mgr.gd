class_name StructureMgr
extends Node

signal structure_state_changed(cellv)

export var debug := false

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
	func _make_resources_string(resources: Dictionary, amount_prefix: String) -> String:
		var s = ""
		for resource_name in resources.keys():
			if s.length() > 0:
				s += ", "
			s += amount_prefix + str(int(resources[resource_name])) + " " + resource_name
		return s			
	func get_construction_resources() -> Dictionary:
		return _get_metadata_item("constructionResources")
	func get_repair_resources() -> Dictionary:
		return _get_metadata_item("repairResources")
	func get_reclamation_resources() -> Dictionary:
		return _get_metadata_item("reclamationResources")
	func get_construction_resources_string() -> String:
		return _make_resources_string(get_construction_resources(), "-")
	func get_repair_resources_string() -> String:
		return _make_resources_string(get_repair_resources(), "-")
	func get_reclamation_resources_string() -> String:
		return _make_resources_string(get_reclamation_resources(), "+")
	func get_power_required() -> float:
		if structure_metadata.has("operatingResources"):
			if structure_metadata["operatingResources"].has("power"):
				return structure_metadata["operatingResources"]["power"]
		return 0.0
	func get_name() -> String:
		return structure_metadata["name"]
	func get_power_provided() -> float:
		if structure_metadata.has("powerProvided"):
			return structure_metadata["powerProvided"]
		return 0.0
	

class StructureData:
	var structure_type_id :int = Constants.StructureTileType.UUC
	var tile_map_cell := Vector2.ZERO
	#if not a power station or UUC then list of power stations that power this cell
	#var power_stations := []
	#total amount of power being used from powered cells or amount of power being given to a non-power station structure
	var power_subscription := 0
	var metadata_wrapped: StructureMetadata
	var disabled := false
	var damaged := false
	var repairing := false
	var reclaiming := false
	var structure_name = ""
	var under_construction := true
	var resources_lacking := []
	var current_animation
	var neighbor_structures_type_counts := {}
	func _init(structure_type_id_: int, tile_map_cell_: Vector2, structure_metadata):
		structure_type_id = structure_type_id_
		tile_map_cell = tile_map_cell_
		metadata_wrapped = StructureMetadata.new(structure_metadata)
	func update_for_power_distribution(total_power_left: float) -> float:
		resources_lacking.clear()
		power_subscription = 0.0
		var power_required = get_required_power()
		if power_required == 0:
			return total_power_left
		if power_required > total_power_left:
			total_power_left = 0.0
			resources_lacking.append("power")
			return total_power_left
		total_power_left -= power_required
		power_subscription = power_required
		return total_power_left

	func _get_name():
		return structure_name
	func _set_name(new_name):
		structure_name = new_name
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
	func get_repair_resources_string() -> String:
		return metadata_wrapped.get_repair_resources_string()
	func get_reclamation_resources_string() -> String:
		return metadata_wrapped.get_reclamation_resources_string()
	func get_name() -> String:
		return metadata_wrapped.get_name()
	func get_required_power() -> float:
		return metadata_wrapped.get_power_required()
	func get_power_provided() -> float:
		return metadata_wrapped.get_power_provided()
	func update_neighbor_structures_type_counts(structures: Dictionary) -> void:
		neighbor_structures_type_counts.clear()
		for direction in Vector2Util.compass_rose_directions:
			var v = tile_map_cell + direction
			if !structures.has(v):
				continue
			var structure: StructureData = structures[v]
			if neighbor_structures_type_counts.has(structure.structure_type_id):
				neighbor_structures_type_counts[structure.structure_type_id] += 1
			else:
				neighbor_structures_type_counts[structure.structure_type_id] = 1
		#print("neighbor structures types counts for tile at %s: %s" % [str(tile_map_cell), str(neighbor_structures_type_counts)])
	func calc_population_support_units(base_units_per_structure: float, proximity_effects: Dictionary) -> float:
		if proximity_effects == null or proximity_effects.size() < 1:
			return base_units_per_structure
		
		var total_neighbor_effects := 0.0
		for neighbor_structure_type_id in neighbor_structures_type_counts.keys():
			var neighbor_structure_type_name = EnumUtil.get_string(StructureTileType, neighbor_structure_type_id)
			if !proximity_effects.has(neighbor_structure_type_name):
				continue
			total_neighbor_effects += base_units_per_structure * proximity_effects[neighbor_structure_type_name] * neighbor_structures_type_counts[neighbor_structure_type_id]
			
		return base_units_per_structure + total_neighbor_effects
			
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
	SignalMgr.register_publisher(self, "structure_state_changed")
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
	emit_signal("structure_state_changed", structure.tile_map_cell)
	_do_reclamation_animation(structure)
	

func repair_structure(cell_v: Vector2) -> void:
	if !_structures.has(cell_v):
		return
	var structure: StructureData = _structures[cell_v]
	if structure.disabled || structure.damaged:
		#refresh_structure_resources()
		_do_repair_animation(structure)


#creates a lists of connected structures (dictionary of tile map cell to structure)
func _get_connected_structure_groups() -> Array:
	#separate structures into connected groups
	#powerstations in those groups will power the structures in that group
	var directions := [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
	var connected_structure_groups := []
	for tile_map_cell in _structures.keys():
		var structure: StructureData = _structures[tile_map_cell]
		if structure.disabled:
			continue
		var neighbor_list := []
		for direction in directions:
			var neighbor_tile_map_cell:Vector2 = structure.tile_map_cell + direction
			for connected_structure_group in connected_structure_groups:
				if connected_structure_group.has(neighbor_tile_map_cell):
					neighbor_list.append((connected_structure_group))
		if neighbor_list.size() == 0:
			var connected_structure_group := {}
			connected_structure_group[structure.tile_map_cell] = structure
			connected_structure_groups.append(connected_structure_group)
		else:
			var new_connected_structure_group := {}
			new_connected_structure_group[structure.tile_map_cell] = structure
			for neighbor in neighbor_list:
				DictionaryUtil.add(new_connected_structure_group, neighbor)
				connected_structure_groups.erase(neighbor)
			connected_structure_groups.append(new_connected_structure_group)
			
	
	return connected_structure_groups


func _get_total_power_provided_in_connect_structure_group(connected_structure_group: Dictionary) -> float:
	var total_power_provided := 0.0
	for tile_map_cell in connected_structure_group.keys():
		var structure: StructureData = connected_structure_group[tile_map_cell]
		if structure.structure_type_id != StructureTileType.Power:
			continue
		total_power_provided += structure.get_power_provided()
	return total_power_provided

var _structure_type_power_sort_priority := [
	StructureTileType.Reclamation,
	StructureTileType.Agriculture,
	StructureTileType.Medical,
	StructureTileType.Residential,
	StructureTileType.Factory,
	StructureTileType.Education,
	StructureTileType.Office,
	StructureTileType.Recreation,
]


func _custom_sort_power_priority(a: StructureData, b: StructureData) -> bool:
	var a_priority = _structure_type_power_sort_priority.find(a.structure_type_id)
	var b_priority = _structure_type_power_sort_priority.find(b.structure_type_id)
	if a_priority < 0 or b_priority < 0:
		printerr("bad structure priority for sorting for power")
	return a_priority < b_priority

#func _debug_print_structure_array(a: Array) -> void:
#	for i in range(a.size()):
#		var s: StructureData = a[i]
#		print("a[%d] = %s" % [i, s.get_name()])


func _get_ordered_list_of_structures_to_power(connected_structure_group: Dictionary) -> Array:
	var structures_needing_power := []
	for tile_map_cell in connected_structure_group.keys():
		var structure: StructureData = connected_structure_group[tile_map_cell]
		if structure.disabled or structure.structure_type_id == StructureTileType.Power or structure.structure_type_id == StructureTileType.UUC:
			continue
		structures_needing_power.append(structure)
	structures_needing_power.sort_custom(self, "_custom_sort_power_priority")
	return structures_needing_power

func refresh_structure_resources(debug: bool = false):

	Game.get_structure_status_overlay_tiles_tile_map().clear()
	var connected_structure_groups = _get_connected_structure_groups()
	for connected_structure_group in connected_structure_groups:
		var total_power_provided = _get_total_power_provided_in_connect_structure_group(connected_structure_group)
		var structures_to_power = _get_ordered_list_of_structures_to_power(connected_structure_group)
		for i in range(structures_to_power.size()):
			var structure_to_power: StructureData = structures_to_power[i]
			total_power_provided = structure_to_power.update_for_power_distribution(total_power_provided)
	
	for structure in _structures.values():
		structure.update_neighbor_structures_type_counts(_structures)
		if structure.disabled:
			Game.get_structure_status_overlay_tiles_tile_map().set_cellv(structure.tile_map_cell, _structure_disable_status_overlay_tile_id[structure.structure_type_id])
			Game.get_separator_boxes_tile_map().set_cellv(structure.tile_map_cell, _structure_lack_resource_status_overlay_tile_id)
		elif structure.resources_lacking.size() > 0:
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
			Game.get_damage_overlay_tile_map().set_cellv(structure.tile_map_cell, -1)


func _refresh_structure_resource_indicators(structure: StructureData):
	var structure_resource_icon_cellv = structure.tile_map_cell * 8 + Vector2(6,6)
	
	if structure.structure_type_id != Constants.StructureTileType.Power and structure.structure_type_id != Constants.StructureTileType.UUC:
		if structure.resources_lacking.has("power"):
			Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 2)
		else:
			Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 0)
	else:
		Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, -1)
	
	#structure_resource_icon_cellv += Vector2.RIGHT
	
#	if structure.resources_lacking.has("population"):
#		Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 3)
#	else:
#		Game.get_resource_indicators_overlay_tile_map().set_cellv(structure_resource_icon_cellv, 1)


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
	emit_signal("structure_state_changed", structure.tile_map_cell)


func _do_reclamation_animation(structure: StructureData) -> void:
	structure.clear_current_animation()
	structure.reclaiming = true
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
	emit_signal("structure_state_changed", structure.tile_map_cell)


func _do_repair_animation(structure: StructureData) -> void:
	structure.repairing = true
	#_separator_boxes_tile_map.set_cellv(structure.tile_map_cell, -1)
	var repair_animation: AnimatedSprite = _repair_animation_class.instance()
	structure.current_animation = repair_animation
	Game.get_construction_repair_etc_animations_parent().add_child(repair_animation)
	repair_animation.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
	repair_animation.play("default")
	yield(repair_animation, "repair_complete")
	structure.disabled = false
	structure.damaged = false
	repair_animation.queue_free()
	structure.disabled = false
	structure.repairing = false
	#_separator_boxes_tile_map.set_cellv(structure.tile_map_cell, _structure_enabled_status_overlay_tile_id)
	refresh_structure_resources(true)
	emit_signal("structure_state_changed", structure.tile_map_cell)

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
		if debug:
			print("disabling structure %s at %s" % [structure.get_name(), str(structure.tile_map_cell)])
		structure.disabled = true
		refresh_structure_resources()
		var interaction_sound = _structure_interaction_temp_sound_class.instance()
		Game.get_construction_repair_etc_animations_parent().add_child(interaction_sound)
		interaction_sound.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
		interaction_sound.play_player_deactivate_sound()
	else:
		if debug:
			print("structure %s at %s already disabled" % [structure.get_name(), str(structure.tile_map_cell)])

	
func enable_structure(cell_v: Vector2):
	if !_structures.has(cell_v):
		return
	var structure: StructureData = _structures[cell_v]
	if structure.disabled:
		if debug:
			print("enabling structure %s at %s" % [structure.get_name(), str(structure.tile_map_cell)])
		structure.disabled = false
		refresh_structure_resources()
		var interaction_sound = _structure_interaction_temp_sound_class.instance()
		Game.get_construction_repair_etc_animations_parent().add_child(interaction_sound)
		interaction_sound.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
		interaction_sound.play_player_reactive_sound()
	else:
		if debug:
			print("structure %s at %s already enabled" % [structure.get_name(), str(structure.tile_map_cell)])

func damage_structure(structure: StructureData):
	structure.set_damaged(true)
	refresh_structure_resources()
	var interaction_sound = _structure_interaction_temp_sound_class.instance()
	Game.get_construction_repair_etc_animations_parent().add_child(interaction_sound)
	interaction_sound.global_position = Game.get_structure_tiles_tile_map().map_to_world(structure.tile_map_cell)
	interaction_sound.play_failure_deactive_sound()
	emit_signal("structure_state_changed", structure.tile_map_cell)

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

func get_functioning_structures_by_type_id(structure_type_id: int) -> Array:
	var functioning_structures := []
	for structure in _structures.values():
		if structure.structure_type_id != structure_type_id:
			continue
		if structure.disabled or structure.damaged or structure.under_construction or structure.lacks_resources():
			continue
		functioning_structures.append(structure)
	return functioning_structures
		
func get_structures_by_type_id(structure_type_id: int) -> Array:
	var structures := []
	for structure in _structures.values():
		if structure.structure_type_id != structure_type_id:
			continue
		structures.append(structure)
	return structures
	
func get_structures() -> Array:
	return _structures.values()

func get_structure_at_world_coord(world_coord: Vector2) -> StructureData:
	var structure_tiles_map := Game.get_structure_tiles_tile_map()
	var map_coord = structure_tiles_map.world_to_map(world_coord)
	if _structures.has(map_coord):
		return _structures[map_coord]
	return null

func get_structure(tile_map_coord: Vector2) -> StructureData:
	if _structures.has(tile_map_coord):
		return _structures[tile_map_coord]
	return null
