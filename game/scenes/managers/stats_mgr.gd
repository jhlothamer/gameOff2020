class_name StatsMgr
extends Node


enum StatType {
	Population,
	Morale,
	Water,
	Food,
	Shelter,
	Clothing,
	Health,
	Education,
	Entertainment
}

const VALUES_KEPT_LIMIT = 100

class Stat:
	var stat_type:int
	var stat_metadata
	var values := []
	func _init(stat_type: int, stat_metadata):
		self.stat_type = stat_type
		self.stat_metadata = stat_metadata
	func push_value(value: float) -> void:
		values.push_front(value)
		if values.size() > VALUES_KEPT_LIMIT:
			var _throw_away = values.pop_back()

var _stats := {}
var _stats_metadata := {}

const stats_metadata_file_path := "res://assets/data/stats.json"

func _ready():
	SignalMgr.register_subscriber(self, "year_has_elapsed", "_on_year_has_elapsed")
	call_deferred("_init_stats")

func _init_stats():
	_load_stats_data()
	var structure_mgr = StructureMgr.get_structure_mgr()
	if structure_mgr == null:
		printerr("did not get structure mgr when initializing stats - stats will never be calculated")
		return
	for stat_name in _stats_metadata.keys():
		var stat_metadata = _stats_metadata[stat_name]
		var stat_type = StatType.keys()[stat_name]
		var stat = Stat.new(stat_type, stat_metadata)
		if stat_metadata.has("startingAmount"):
			stat.push_value(stat_metadata["startingAmount"])
		elif stat_metadata.has("producedByStructure") and stat_metadata.has("unitsPerStructure"):
			var producingStructures = structure_mgr.get_functioning_structures_by_type_name(stat_metadata["producedByStructure"])
			stat.push_value(producingStructures.size() * stat_metadata["unitsPerStructure"])
		_stats[stat_name] = stat
		


func _load_stats_data():
	var data_file: File = File.new()
	var error = data_file.open(stats_metadata_file_path, File.READ)
	if error != OK:
		print("error opening data file")
		data_file.close()
		return
	var json_text = data_file.get_as_text()
	var parse_results:JSONParseResult =  JSON.parse(json_text)
	if parse_results.error != OK:
		print("error parsing data.")
		print(parse_results.error_string)
		print(parse_results.error_line)
		return
	_stats_metadata = parse_results.result
	data_file.close()

func _update_structure_produced_stats():
	var structure_mgr = StructureMgr.get_structure_mgr()
	for stat in _stats:
		if stat.stat_metadata.has("producedByStructure") and stat.stat_metadata.has("unitsPerStructure"):
			var producingStructures = structure_mgr.get_functioning_structures_by_type_name(stat.stat_metadata["producedByStructure"])
			stat.previous_value = stat.value
			stat.push_value(producingStructures.size() * stat.stat_metadata["unitsPerStructure"])

func _on_year_has_elapsed() -> void:
	var structure_mgr := StructureMgr.get_structure_mgr()
	if structure_mgr == null:
		return
	_update_structure_produced_stats()










