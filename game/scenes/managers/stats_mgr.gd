class_name StatsMgr
extends Node

signal stats_updated()
signal population_crashed_game_over()

enum StatType {
	Population,
	Morale,
	Water,
	Food,
	Shelter,
	Clothing,
	Health,
	Education,
	Entertainment,
	Power,
	Administration,
	#
	PopulationDelta,
	TotalPowerRequired,
}

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
		if stat_metadata.has("populationSchedule"):
			return stat_metadata["populationSchedule"].keys().size() > 0
		return false
	
export var debug := false


var _stats := {}
var _stats_by_produced_by_structure_id := {}
var _stats_metadata := {}

const stats_metadata_file_path := "res://assets/data/stats.json"


func _ready():
	Globals.set("StatsMgr", self)
	SignalMgr.register_subscriber(self, "stat_cycle_time_has_elapsed", "_on_stat_cycle_time_has_elapsed")
	SignalMgr.register_publisher(self, "stats_updated")
	SignalMgr.register_publisher(self, "population_crashed_game_over")
	SignalMgr.register_subscriber(self, "time_has_expired", "_on_time_has_expired")
	_load_stats_data()
	call_deferred("_init_stats")

static func get_stat_mgr() -> StatsMgr:
	return Globals.get("StatsMgr")

func _init_stats():
	var structure_mgr = StructureMgr.get_structure_mgr()
	if structure_mgr == null:
		printerr("did not get structure mgr when initializing stats - stats will never be calculated")
		return
	for stat_name in EnumUtil.get_names_string_array(StatType):
		var stat_type_id = EnumUtil.get_id(StatType, stat_name) #StatType.keys()[stat_name]

		if !_stats_metadata.has(stat_name):
			var stat = Stat.new(stat_name, stat_type_id, {})
			stat.push_value(0.0)
			_stats[stat_name] = stat
			continue
		
		var stat_metadata = _stats_metadata[stat_name]
		
		var stat = Stat.new(stat_name, stat_type_id, stat_metadata)
		_stats[stat_name] = stat
		
		if stat_metadata.has("startingAmount"):
			stat.push_value(stat_metadata["startingAmount"])
		elif stat_metadata.has("producedByStructure") and stat_metadata.has("unitsPerStructure"):
			var producingStructures = structure_mgr.get_functioning_structures_by_type_name(stat_metadata["producedByStructure"])
			stat.push_value(producingStructures.size() * stat_metadata["unitsPerStructure"])
		if stat_metadata.has("producedByStructure"):
			var produced_by_structure_id := EnumUtil.get_id(Constants.StructureTileType, stat_metadata["producedByStructure"])
			_stats_by_produced_by_structure_id[produced_by_structure_id] = stat
	emit_signal("stats_updated")


func _get_stat(stat_type: int) -> Stat:
	var stat_name = EnumUtil.get_string(StatType, stat_type)
	if !_stats.has(stat_name):
		return null
	return _stats[stat_name]

func get_stat_by_name(stat_type_name: String) -> Stat:
	if !_stats.has(stat_type_name):
		return null
	return _stats[stat_type_name]



func _load_stats_data():
	_stats_metadata = FileUtil.load_json_data(stats_metadata_file_path)


func _update_structure_produced_stats():
	var structure_mgr = StructureMgr.get_structure_mgr()
	for stat in _stats.values():
		if stat.stat_metadata.has("producedByStructure") and stat.stat_metadata.has("unitsPerStructure"):
			var producingStructures = structure_mgr.get_functioning_structures_by_type_name(stat.stat_metadata["producedByStructure"])
			stat.push_value(producingStructures.size() * stat.stat_metadata["unitsPerStructure"])


func _find_schedule_value(schedule: Dictionary, lookup_value: float) -> float:
	var schedule_value := .0
	
	var matching_value := 100.0
	
	for key in schedule.keys():
		var entry_value = float(key)
		if lookup_value <= entry_value and entry_value <= matching_value:
			schedule_value = schedule[key]
			matching_value = entry_value
	
	return schedule_value


func _calculate_population_delta_from_pop_schedules(current_population: float) -> int:
	var population_delta := 0
	
	for stat_type_id in EnumUtil.get_array(StatType):
		var stat = _get_stat(stat_type_id)
		var stat_metadata = stat.stat_metadata
		if !stat_metadata.has("populationSchedule"):
			continue
		var stat_value = stat.get_value()
		if stat_value > current_population:
			continue
		var percent_needed_satisfied: float = stat_value / current_population
		var population_schedule = stat_metadata["populationSchedule"]
		var stat_population_delta = _find_schedule_value(population_schedule, percent_needed_satisfied)
		population_delta += stat_population_delta
	
	if debug:
		print("calculated population delta is: " + str(population_delta))
	
	return population_delta

func _get_overage_percent_for_needed_stat(stat_type_id: int, current_population) -> float:
	var stat_name = EnumUtil.get_string(StatType, stat_type_id)
	var stat = _stats[stat_name]
	var stat_value = stat.get_value()
	
	if stat_value < current_population:
		return 0.0
	
	var overage_percent = float(stat_value) / float(current_population) - 1.0
	
	return overage_percent

# morale stat is a measure of population morale
# it's a number from -1 to 1 with 1 being high morale and -1 being really sad
func _calc_population_morale(min_overage_percent) -> float:
	var morale_stat := _get_stat(StatType.Morale)
	var morale_delta := .0
	
	#morale affected by population changes (deaths, births)
	var population_delta_stat := _get_stat(StatType.PopulationDelta)
	var population_delta = population_delta_stat.get_value()
	if population_delta > .0:
		# population increased - morale should too
		morale_delta += .1
	elif population_delta < .0:
		# population decreased in the current cycle
		# check what happened last 10 cycles
		if population_delta_stat.values.size() > 10:
			var population_delta_avg_10_cycles = StatsUtil.mean(population_delta_stat.values, 10)
			if population_delta_avg_10_cycles > .0:
				#last 10 cycles population has increased on average
				#morale not as affected
				morale_delta -= .1
			else:
				#last 10 cycles population has decreased on average
				#morale more affected
				morale_delta -= .2
	
	#morale affected by needed stats (resources) such as food and water
	if min_overage_percent > .0:
		morale_delta += .1
	
	
	var morale_value = morale_stat.get_value()
	morale_value = clamp(morale_value + morale_delta, -1.0, 1.0)
	morale_stat.push_value(morale_value)
	
	return morale_value

func _calculate_min_verage_percent() -> float:
	var population_stat := _get_stat(StatType.Population)
	var current_population = population_stat.get_value()
	var population_increase_percent_limit: float = population_stat.stat_metadata["increasePercentLimit"]
	var min_overage_percent := population_increase_percent_limit
	for needed_stat in [StatType.Water, StatType.Food]:
		min_overage_percent = min(min_overage_percent, _get_overage_percent_for_needed_stat(needed_stat, current_population))
	return min_overage_percent


func _update_total_power_required_stat(structure_mgr: StructureMgr):
	var total_power_required_stat := _get_stat(StatType.TotalPowerRequired)
	var total = 0.0
	for structure in structure_mgr.get_structures():
		total += structure.get_power_required()
	total_power_required_stat.push_value(total)


func _on_stat_cycle_time_has_elapsed() -> void:
	var structure_mgr := StructureMgr.get_structure_mgr()
	if structure_mgr == null:
		return
	
	_update_structure_produced_stats()

	_update_total_power_required_stat(structure_mgr)

	var population_stat := _get_stat(StatType.Population)
	var current_population = population_stat.get_value()
	
	var population_delta := _calculate_population_delta_from_pop_schedules(current_population)
	
	var population_delta_stat := _get_stat(StatType.PopulationDelta)
	population_delta_stat.push_value(population_delta)
	

	#calculate by how much more capacity we have on necessary stats than the current population needs
	#  this will determine if and by how much the population can grow
#	var population_increase_percent_limit: float = population_stat.stat_metadata["increasePercentLimit"]
#	var min_overage_percent := population_increase_percent_limit
#	for needed_stat in [StatType.Water, StatType.Food]:
#		min_overage_percent = min(min_overage_percent, _get_overage_percent_for_needed_stat(needed_stat, current_population))
	
	var min_overage_percent := _calculate_min_verage_percent()
	
	_calc_population_morale(min_overage_percent)
	
	if debug:
		print("min overage percent is :" + str(min_overage_percent))
	
	if min_overage_percent > 0.0:
		var possible_population_increase = floor(min_overage_percent * current_population) / 2
		if debug:
			print("population increase is :" + str(possible_population_increase))
		population_delta += possible_population_increase 
	
	current_population += population_delta
	
	population_stat.push_value(current_population)
	
	emit_signal("stats_updated")
	
	
	var loose_game_population_amount : float = population_stat.stat_metadata["looseGameAmount"]
	
	if loose_game_population_amount > current_population:
		print("population crashed!")
		emit_signal("population_crashed_game_over")
		return
		
	var warn_loose_game_population_amount = population_stat.stat_metadata["warnLooseGameAmount"]
	if warn_loose_game_population_amount >= current_population:
		var prev_population_value = population_stat.get_prev_value()
		if warn_loose_game_population_amount < prev_population_value:
			HudAlertsMgr.add_hud_alert("Population is crashing!")
			HudAlertsMgr.add_hud_alert("Game over if population drops below %d" % loose_game_population_amount)


func get_needed_number_of_structures(structure_type_id: int) -> float:
	if !_stats_by_produced_by_structure_id.has(structure_type_id):
		return 0.0
	var stat = _stats_by_produced_by_structure_id[structure_type_id]
	var structure_mgr := StructureMgr.get_structure_mgr()
	var structure_type_name := EnumUtil.get_string(Constants.StructureTileType, structure_type_id)
	var function_structures = structure_mgr.get_functioning_structures_by_type_name(structure_type_name)
	
	var population_stat := _get_stat(StatType.Population)
	var population := population_stat.get_value()
	return population / stat.stat_metadata["unitsPerStructure"]


func get_stat_provided_by_structure_type_id(structure_type_id: int) -> Stat:
	if _stats_by_produced_by_structure_id.has(structure_type_id):
		return _stats_by_produced_by_structure_id[structure_type_id]
	return null

func get_win_game_population_amount() -> int:
	var population_stat_metadata := get_stat_metadata(StatType.Population)
	return _get_win_game_population_amount(population_stat_metadata)


func _get_win_game_population_amount(population_stat_metadata) -> int:
	var difficulty_level = DifficultySettings.get_difficulty_setting()
	if difficulty_level == DifficultySettings.DifficultyLevels.Easy:
		return population_stat_metadata["winGameAmountEasy"]
	elif difficulty_level == DifficultySettings.DifficultyLevels.Medium:
		return population_stat_metadata["winGameAmountMedium"]
	elif difficulty_level == DifficultySettings.DifficultyLevels.Hard:
		return population_stat_metadata["winGameAmountHard"]
	else:
		assert(false)
	return 0


func get_win_game_population_amounts() -> Dictionary:
	var amounts := {}
	var population_stat_metadata := get_stat_metadata(StatType.Population)
	amounts[DifficultySettings.DifficultyLevels.Easy] = population_stat_metadata["winGameAmountEasy"]
	amounts[DifficultySettings.DifficultyLevels.Medium] = population_stat_metadata["winGameAmountMedium"]
	amounts[DifficultySettings.DifficultyLevels.Hard] = population_stat_metadata["winGameAmountHard"]
	return amounts

func get_stat_metadata(stat_type: int) -> Dictionary:
	if _stats_metadata == null:
		return {}
	var stat_name = EnumUtil.get_string(StatType, stat_type)
	return _stats_metadata[stat_name]


func _on_time_has_expired():
	var population_stat := _get_stat(StatType.Population)
	var current_population = population_stat.get_value()
	var loose_game_population_amount : float = population_stat.stat_metadata["looseGameAmount"]
	if loose_game_population_amount > current_population:
		print("population crashed!")
		emit_signal("population_crashed_game_over")
		return
	var win_game_population_amount : float = _get_win_game_population_amount(population_stat.stat_metadata)
	if win_game_population_amount > current_population:
		Globals.set("won", false)
	else:
		Globals.set("won", true)
	transitionMgr.transitionTo(Constants.ENDING_SCENE_PATH, Constants.TRANSITION_SPEED, true)

