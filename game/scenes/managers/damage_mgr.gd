extends Node

export var structure_mgr: NodePath

var _structure_mgr: StructureMgr


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalMgr.register_subscriber(self, "random_damage_test_clicked", "_on_random_damage_test_clicked")
	if structure_mgr != null:
		_structure_mgr = get_node_or_null(structure_mgr)


func _on_random_damage_test_clicked():
	if structure_mgr == null:
		return
	var non_damaged_structures = _structure_mgr.get_damagable_structures()
	if non_damaged_structures == null || non_damaged_structures.size() < 1:
		return
	var rand_structure: StructureMgr.StructureData = ArrayUtil.get_rand(non_damaged_structures)
	rand_structure.set_damaged(true)
	_structure_mgr.refresh_structure_resources()
