class_name ResourceMgr
extends Node


const resource_data_file_path = "res://assets/data/resources.json"

#export var structure_mgr: NodePath
#
#var _structure_mgr: StructureMgr


var _resource_data := {}
# resource name to current amount
var _resource_amounts := {}

static func get_resource_mgr() -> ResourceMgr:
	return Globals.get("ResourceMgr")

func _ready():
	SignalMgr.register_subscriber(self, "structure_tile_placed", "_on_structure_tile_placed")
	SignalMgr.register_subscriber(self, "structure_tile_reclaimed", "_on_structure_tile_reclaimed")
	SignalMgr.register_subscriber(self, "structure_tile_repaired", "_on_structure_tile_repaired")
	SignalMgr.register_subscriber(self, "structure_tile_enabled", "_on_structure_tile_enabled")
	SignalMgr.register_subscriber(self, "structure_tile_disabled", "_on_structure_tile_disabled")
	Globals.set("ResourceMgr", self)
#	if structure_mgr != null:
#		_structure_mgr = get_node_or_null(structure_mgr)
	
	var resource_file: File = File.new()
	var error = resource_file.open(resource_data_file_path, File.READ)
	if error != OK:
		print("error opening resource data file")
		resource_file.close()
		return
	_resource_data = parse_json(resource_file.get_as_text())
	resource_file.close()
	
	var resources = _resource_data["resources"]
	for resource_name in resources.keys():
		var resource = resources[resource_name]
		_resource_amounts[resource_name] = resource["starting_amount"]


func have_enough_resources_for_constructions(structure_type_id: int) -> bool:
	var construction_resources = StructureMgr.get_structure_mgr().get_structure_construction_resources(structure_type_id)
	
	for resource_name in construction_resources.keys():
		if !_resource_amounts.has(resource_name):
			print("construction resource name does not exist!  name = " + resource_name)
			continue
		if construction_resources[resource_name] > _resource_amounts[resource_name]:
			return false
	
	return true


func decrement_resources_for_construction(structure_type_id: int) -> bool:
	var construction_resources = StructureMgr.get_structure_mgr().get_structure_construction_resources(structure_type_id)
	
	if !have_enough_resources_for_constructions(structure_type_id):
		return false
	
	for resource_name in construction_resources.keys():
		if !_resource_amounts.has(resource_name):
			print("construction resource name does not exist!  name = " + resource_name)
			continue
		_resource_amounts[resource_name] -= construction_resources[resource_name]
	
	return true


func get_resource_amounts():
	return _resource_amounts

func _on_structure_tile_placed(structure_tile_type, cell_v):
	if decrement_resources_for_construction(structure_tile_type):
		StructureMgr.get_structure_mgr().add_structure(structure_tile_type, cell_v)
	else:
		print("didn't have enough resources to contruct structure")


func _on_structure_tile_reclaimed(_structure_tile_type, cell_v):
	#increment resources by reclamation amounts
	StructureMgr.get_structure_mgr().remove_structure(cell_v)


func _on_structure_tile_repaired(_structure_tile_type, cell_v):
	#decrement resources by repair amounts
	StructureMgr.get_structure_mgr().repair_structure(cell_v)


func _on_structure_tile_enabled(_structure_tile_type, cell_v):
	StructureMgr.get_structure_mgr().enable_structure(cell_v)


func _on_structure_tile_disabled(structure_tile_type, cell_v):
	StructureMgr.get_structure_mgr().disable_structure(cell_v)


