extends "res://scenes/managers/damage_mgr_interface.gd"

#export var structure_mgr: NodePath
export var min_damage_time_interval = 15
export var max_damage_time_interval = 180


export var damage_active := true
export var debug := false

onready var _damage_timer := $DamageTimer

func _enter_tree():
	ServiceMgr.register_service(DamageMgr, self)


func _ready():
	SignalMgr.register_subscriber(self, "random_damage_test_clicked", "_on_random_damage_test_clicked")
	if damage_active:
		_start_random_damage_timer()


func _on_random_damage_test_clicked():
	damage_active = !damage_active
	if damage_active:
		_start_random_damage_timer()
	else:
		_damage_timer.stop()

func _start_random_damage_timer():
	if !damage_active:
		return
	_damage_timer.wait_time = rand_range(min_damage_time_interval,max_damage_time_interval)
	_damage_timer.start()
	if debug:
		print("Damage timer set to wait for " + str(_damage_timer.wait_time) + " seconds")

func _on_DamageTimer_timeout():
	if !damage_active:
		_damage_timer.stop()
		return
	damage_random_structure()

func deactivate() -> void:
	damage_active = false
	_damage_timer.stop()

func activate() -> void:
	damage_active = true
	_start_random_damage_timer()
	
func damage_random_structure() -> StructureMgr.StructureData:
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	var non_damaged_structures = structure_mgr.get_damagable_structures()
	if non_damaged_structures == null || non_damaged_structures.size() < 1:
		print("No valid structures to damage")
		return null
	var rand_structure: StructureMgr.StructureData = ArrayUtil.get_rand(non_damaged_structures)
	structure_mgr.damage_structure(rand_structure)
	# set random time for next damage
	_start_random_damage_timer()
	var structure_metadata := structure_mgr.get_structure_metadata(rand_structure.structure_type_id)
	var structure_name = structure_metadata.get_name()
	HudAlertsMgr.add_hud_alert(structure_name + " Damaged")
	return rand_structure

