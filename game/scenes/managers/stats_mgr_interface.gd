class_name StatsMgr

extends Node

const VALUES_KEPT_LIMIT = 100


class Stat:
	var stat_name := ""
	var stat_type_id:int
	var stat_metadata
	var values := []
	func _init(stat_name, stat_type_id: int, stat_metadata):
		self.stat_name = stat_name
		self.stat_type_id = stat_type_id
		self.stat_metadata = stat_metadata
	func push_value(value: float) -> void:
		values.push_front(value)
		if values.size() > VALUES_KEPT_LIMIT:
			var _throw_away = values.pop_back()
	func get_value() -> float:
		if values.size() < 1:
			return 0.0
		return values[0]
	func get_prev_value() -> float:
		if values.size() < 2:
			return get_value()
		return values[1]
	func get_delta() -> float:
		if values.size() < 2:
			return 0.0
		return values[0] - values[1]
	func get_produced_by_structure() -> String:
		if stat_metadata.has("produceByStructure"):
			return stat_metadata["producedByStructure"]
		return ""
	func get_units_per_structure() -> float:
		if stat_metadata.has("unitsPerStructure"):
			return stat_metadata["unitsPerStructure"]
		return 0.0
	func has_population_schedule() -> bool:
		return stat_metadata.has("populationSchedule")
#		if stat_metadata.has("populationSchedule"):
#			return stat_metadata["populationSchedule"].keys().size() > 0
#		return false
	func has_overcapacity_limit() -> bool:
		return stat_metadata.has("overCapacityLimit")
	func get_overcapcity_limit() -> float:
		if !stat_metadata.has("overCapacityLimit"):
			return -1.0
		return float(stat_metadata["overCapacityLimit"])



func get_stat_by_name(stat_type_name: String) -> Stat:
	return null


func get_win_game_population_amount() -> int:
	return -1


func get_win_game_population_amounts() -> Dictionary:
	return {}


func get_stat(stat_type: int) -> Stat:
	return null


func get_stat_provided_by_structure_type_id(structure_type_id: int) -> Stat:
	return null


func calc_structure_produced_stats(stat: Stat, producing_structures: Array) -> float:
	return INF

