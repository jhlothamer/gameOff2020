extends Node

export var structure_mgr: NodePath
export var min_damage_time_interval = 1
export var max_damage_time_interval = 5

var _structure_mgr: StructureMgr

var damage_active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalMgr.register_subscriber(self, "random_damage_test_clicked", "_on_random_damage_test_clicked")
	if structure_mgr != null:
		_structure_mgr = get_node_or_null(structure_mgr)

func _on_random_damage_test_clicked():
	if structure_mgr == null:
		return
	damage_active = !damage_active
	if damage_active:
		_start_random_damage_timer()
	else:
		$DamageTimer.stop()

func _start_random_damage_timer():
	if !damage_active:
		return
	$DamageTimer.wait_time = rand_range(min_damage_time_interval,max_damage_time_interval)
	$DamageTimer.start()

func _on_DamageTimer_timeout():
	if !damage_active:
		$DamageTimer.stop()
		return
	var non_damaged_structures = _structure_mgr.get_damagable_structures()
	if non_damaged_structures == null || non_damaged_structures.size() < 1:
		print("No valid structures to damage")
		return
	var rand_structure: StructureMgr.StructureData = ArrayUtil.get_rand(non_damaged_structures)
	rand_structure.set_damaged(true)
	var structure_mgr := StructureMgr.get_structure_mgr()
	_structure_mgr.refresh_structure_resources()
	print("damaged structure " + structure_mgr._structure_id_to_name[rand_structure.structure_type_id] )
	# set random time for next damage
	_start_random_damage_timer()
