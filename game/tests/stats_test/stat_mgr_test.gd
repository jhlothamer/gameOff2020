extends Control

signal year_has_elapsed()

onready var _label := $Label
onready var _stat_mgr: StatsMgr = $StatsMgr

func _ready():
	SignalMgr.register_publisher(self, "year_has_elapsed")
	Globals.set("StructureMgr", self)
	yield(_stat_mgr,"stats_updated")
	_update_population_label()

var _function_structures_count_by_type_name := {
	"Power": 1,
	"Agriculture": 5, #4
	"Residential": 2,
	"Office": 1,
	"Education": 2,
	"Medical": 1, #2
	"Reclamation": 3, #2
	"Factory": 0, #1
	"Recreation": 2
}


func get_functioning_structures_by_type_name(structure_type_name: String) -> Array:
	var functioning_structures := []
	
	var count = _function_structures_count_by_type_name[structure_type_name]
	for i in range(count):
		functioning_structures.append(StructureMgr.StructureData.new(0, Vector2.ZERO, null))

	return functioning_structures

func _update_population_label():
	var population_stat = _stat_mgr._get_stat(StatsMgr.StatType.Population)
	var population = population_stat.get_value()
	_label.text = str(population)

func _on_SignalYearBtn_pressed():
	emit_signal("year_has_elapsed")
	#yield(_stat_mgr, "stats_updated")
	_update_population_label()
	
