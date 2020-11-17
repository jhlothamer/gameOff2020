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

class Stat:
	var stat_type:int
	var value: float = 0.0
	var previous_value: float = INF
	func _init(stat_type: int):
		self.stat_type = stat_type

var _structure_mgr: StructureMgr
var _stats := {}

func _ready():
	SignalMgr.register_subscriber(self, "year_has_elapsed", "_on_year_has_elapsed")
	_structure_mgr = StructureMgr.get_structure_mgr()
	
	print(StatType.keys()[StatType.Population])
	print("======================")
	for key in StatType.keys():
		print(key)
		
	

func _init_stats():
	pass


func _on_year_has_elapsed() -> void:
	if _structure_mgr == null:
		return

