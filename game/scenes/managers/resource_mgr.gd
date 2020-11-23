class_name ResourceMgr
extends Node

signal resources_updated()

const resource_data_file_path = "res://assets/data/resources.json"


var _resource_data := {}
# resource name to current amount
var _resource_amounts := {}

static func get_resource_mgr() -> ResourceMgr:
	return Globals.get("ResourceMgr")

func _ready():
	SignalMgr.register_publisher(self, "resources_updated")
	SignalMgr.register_subscriber(self, "structure_tile_placed", "_on_structure_tile_placed")
	SignalMgr.register_subscriber(self, "structure_tile_reclaimed", "_on_structure_tile_reclaimed")
	SignalMgr.register_subscriber(self, "structure_tile_repaired", "_on_structure_tile_repaired")
	SignalMgr.register_subscriber(self, "structure_tile_enabled", "_on_structure_tile_enabled")
	SignalMgr.register_subscriber(self, "structure_tile_disabled", "_on_structure_tile_disabled")
	Globals.set("ResourceMgr", self)
#	if structure_mgr != null:
#		_structure_mgr = get_node_or_null(structure_mgr)
	
	_resource_data = FileUtil.load_json_data(resource_data_file_path)
	
	var resources = _resource_data["resources"]
	for resource_name in resources.keys():
		var resource = resources[resource_name]
		_resource_amounts[resource_name] = resource["starting_amount"]
	
	call_deferred("_signal_resource_init")

func _signal_resource_init():
	emit_signal("resources_updated")

func have_enough_resources_for_constructions(structure_type_id: int) -> bool:
	var structure_mgr = StructureMgr.get_structure_mgr()
	var structure_metadata: StructureMgr.StructureMetadata = structure_mgr.get_structure_metadata(structure_type_id)
	return _have_enough_resources_for_action(structure_metadata.get_construction_resources())

func _have_enough_resources_for_action(action_resources: Dictionary) -> bool:
	for resource_name in action_resources.keys():
		if !_resource_amounts.has(resource_name):
			print("construction resource name does not exist!  name = " + resource_name)
			continue
		if action_resources[resource_name] > _resource_amounts[resource_name]:
			return false

	return true

func _decrement_resources_for_construction(structure_type_id: int) -> bool:
	var structure_mgr = StructureMgr.get_structure_mgr()
	var structure_metadata: StructureMgr.StructureMetadata = structure_mgr.get_structure_metadata(structure_type_id)
	
	var construction_resources = structure_metadata.get_construction_resources()
	if !_have_enough_resources_for_action(construction_resources):
		return false
	
	var resources_updated := false
	for resource_name in construction_resources.keys():
		if !_resource_amounts.has(resource_name):
			print("construction resource name does not exist!  name = " + resource_name)
			continue
		_resource_amounts[resource_name] -= construction_resources[resource_name]
		resources_updated = true
	
	if resources_updated:
		emit_signal("resources_updated")
	
	return true

func _decrement_resources_for_repair(structure_type_id: int) -> bool:
	
	var structure_mgr = StructureMgr.get_structure_mgr()
	var structure_metadata: StructureMgr.StructureMetadata = structure_mgr.get_structure_metadata(structure_type_id)
	
	var repair_resources = structure_metadata.get_repair_resources()
	if !_have_enough_resources_for_action(repair_resources):
		return false
	
	var resources_updated := false
	for resource_name in repair_resources.keys():
		if !_resource_amounts.has(resource_name):
			print("repair resource name does not exist!  name = " + resource_name)
			continue
		_resource_amounts[resource_name] -= repair_resources[resource_name]
		resources_updated = true
	
	if resources_updated:
		emit_signal("resources_updated")
	
	return true


func _increment_resources_for_reclamation(structure_type_id: int):

	var structure_mgr = StructureMgr.get_structure_mgr()
	var structure_metadata: StructureMgr.StructureMetadata = structure_mgr.get_structure_metadata(structure_type_id)
	
	var reclamation_resources = structure_metadata.get_reclamation_resources()
	
	var resources_updated := false
	for resource_name in reclamation_resources.keys():
		if !_resource_amounts.has(resource_name):
			print("repair resource name does not exist!  name = " + resource_name)
			continue
		_resource_amounts[resource_name] += reclamation_resources[resource_name]
		resources_updated = true
	
	if resources_updated:
		emit_signal("resources_updated")
	
	

func get_resource_amounts():
	return _resource_amounts

func get_resource_amount(resource_name) -> float:
	if !_resource_amounts.has(resource_name):
		return INF
	return _resource_amounts[resource_name]

func _on_structure_tile_placed(structure_tile_type, cell_v):
	if _decrement_resources_for_construction(structure_tile_type):
		StructureMgr.get_structure_mgr().add_structure(structure_tile_type, cell_v)
	else:
		print("didn't have enough resources to contruct structure")


func _on_structure_tile_reclaimed(structure_tile_type, cell_v):
	#increment resources by reclamation amounts
	_increment_resources_for_reclamation(structure_tile_type)
	StructureMgr.get_structure_mgr().remove_structure(cell_v)


func _on_structure_tile_repaired(structure_tile_type, cell_v):
	#decrement resources by repair amounts
	if(!_decrement_resources_for_repair(structure_tile_type)):
		return
	StructureMgr.get_structure_mgr().repair_structure(cell_v)


func _on_structure_tile_enabled(_structure_tile_type, cell_v):
	StructureMgr.get_structure_mgr().enable_structure(cell_v)


func _on_structure_tile_disabled(structure_tile_type, cell_v):
	StructureMgr.get_structure_mgr().disable_structure(cell_v)


