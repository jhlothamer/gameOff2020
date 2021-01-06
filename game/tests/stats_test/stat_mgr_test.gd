extends Control

signal stat_cycle_time_has_elapsed()

onready var _label := $VBoxContainer/PopulationLabel
onready var _stat_mgr: StatsMgr = $StatsMgr
onready var _functioning_structure_counts := $FunctioningStructuresCount
onready var _structure_mgr: StructureMgr = $StructureMgr
onready var _year_signal_timer := $YearSignalTimer
onready var _stat_values := $StatValues

const functioning_structure_count_class := preload("res://tests/stats_test/functioning_structure_count.tscn")
const stat_value_class := preload("res://tests/stats_test/stat_value.tscn")

var _function_structures_count_by_type_name := {
	"Power": 1,
	"Agriculture": 5, #4
	"Residential": 2,
	"Office": 1,
	"Education": 2,
	"Medical": 1, #2
	"Reclamation": 3, #2
	"Factory": 1, #1
	"Recreation": 2
}

var _functioning_structure_count_control_by_type_name := {}
var _stat_value_controls_by_stat_name := {}

func _ready():
	SignalMgr.register_publisher(self, "stat_cycle_time_has_elapsed")
	SignalMgr.register_subscriber(self, "functional_structure_count_changed", "_on_functional_structure_count_changed")
	Globals.set("StructureMgr", self)
	yield(_stat_mgr,"stats_updated")
	_update_population_label()
	#SignalMgr.register_subscriber(self, "stats_updated", "_on_stats_updated")
	
	for structure_type_name in _function_structures_count_by_type_name.keys():
		var functioning_structure_count := functioning_structure_count_class.instance()
		_functioning_structure_counts.add_child(functioning_structure_count)
		functioning_structure_count.structure_type_name = structure_type_name
		functioning_structure_count.functional_count = _function_structures_count_by_type_name[structure_type_name]
		_functioning_structure_count_control_by_type_name[structure_type_name] = functioning_structure_count
		var structure_type_id = EnumUtil.get_id(StructureMgr.StructureTileType, structure_type_name)
		functioning_structure_count.num_structures_needed = _stat_mgr.get_needed_number_of_structures(structure_type_id)

	NodeUtil.remove_children(_stat_values)
	for stat_type_name in EnumUtil.get_names_string_array(StatsMgr.StatType):
		var stat = _stat_mgr.get_stat_by_name(stat_type_name)
		var stat_value_control = stat_value_class.instance()
		_stat_values.add_child(stat_value_control)
		stat_value_control.stat_name = stat_type_name
		stat_value_control.stat_value = stat.get_value()
		_stat_value_controls_by_stat_name[stat_type_name] = stat_value_control
		

func get_functioning_structures_by_type_name(structure_type_name: String) -> Array:
	var functioning_structures := []
	
	var count = 0
	if _functioning_structure_count_control_by_type_name.has(structure_type_name):
		var functioning_structure_count_control = _functioning_structure_count_control_by_type_name[structure_type_name]
		count = functioning_structure_count_control.functional_count
	else:
		count = _function_structures_count_by_type_name[structure_type_name]
	
	for i in range(count):
		functioning_structures.append(StructureMgr.StructureData.new(0, Vector2.ZERO, null))

	return functioning_structures

func _update_population_label():
	var population_stat = _stat_mgr._get_stat(StatsMgr.StatType.Population)
	var population = population_stat.get_value()
	_label.text = str(population)

func _update_stat_value_controls():
	for stat_value_control in _stat_value_controls_by_stat_name.values():
		var stat = _stat_mgr.get_stat_by_name(stat_value_control.stat_name)
		stat_value_control.stat_value = stat.get_value()

func _on_SignalYearBtn_pressed():
	emit_signal("stat_cycle_time_has_elapsed")
	#yield(_stat_mgr, "stats_updated")
	_update_population_label()
	_update_stat_value_controls()
	
func _on_functional_structure_count_changed(structure_type_name: String, functional_count: int) -> void:
	_function_structures_count_by_type_name[structure_type_name] = functional_count


func _on_SecondsPerYearSpinBox_value_changed(value):
	_year_signal_timer.wait_time = value


func _on_YearSignalTimerActiveCheckBox_toggled(button_pressed):
	if button_pressed:
		_year_signal_timer.start()
	else:
		_year_signal_timer.stop()


func _on_YearSignalTimer_timeout():
	emit_signal("stat_cycle_time_has_elapsed")
	_update_population_label()
	_update_stat_value_controls()

func _on_stats_updated():
	_update_population_label()

