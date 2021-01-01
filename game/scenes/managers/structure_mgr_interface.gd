class_name StructureMgr
extends Node

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
	func get_short_name() -> String:
		return structure_metadata["shortName"]
	func get_construction_short_cut_key() -> String:
		return structure_metadata["constructionShortCut"]
	func get_power_provided() -> float:
		if structure_metadata.has("powerProvided"):
			return structure_metadata["powerProvided"]
		return 0.0
	

class StructureData:
	var structure_type_id :int = StructureTileType.UUC
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
	func get_short_name() -> String:
		return metadata_wrapped.get_short_name()
	
export var disable_enable_allowed := true

func get_structure(tile_map_coord: Vector2) -> StructureData:
	return null


func get_structure_metadata(structure_type_id: int) -> StructureMetadata:
	return null


func get_structures_by_type_id(structure_type_id: int) -> Array:
	return []


func get_functioning_structures_by_type_id(structure_type_id: int) -> Array:
	return []


func get_structure_by_mouse_global_position() -> StructureData:
	return null


func get_structure_at_world_coord(world_coord: Vector2) -> StructureData:
	return null


func get_functioning_structures_by_type_name(type_name: String) -> Array:
	return []
