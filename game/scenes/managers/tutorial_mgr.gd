extends "res://scenes/managers/tutorial_mgr_interface.gd"

signal TutorialComplete()
signal ToggleNoMusic(no_music)
signal HighlightConstructionButton(structure_type_id, highlight_flag)
signal BlinkConstructionButtonHighlight(structure_type_id)


signal highlight_ore_display()
signal hide_ore_display_highlight()
signal highlight_total_power()
signal hide_total_power_highlight()
signal highlight_power_needed()
signal hide_powered_needed_highlight()
signal highlight_population()
signal hide_population_highlight()
signal highlight_harvester_launch_button()
signal hide_harvester_launch_button_highlight()
signal highlight_construction_buttons()
signal hide_construction_buttons_highlight()
signal extend_construction_drawer()
signal retract_construction_drawer()
signal highlight_construction_drawer()
signal hide_construction_drawer_highlight()
signal enable_structure_tile_tooltip()
signal disable_structure_tile_tooltip()


#tutorial signals
signal zoom_step_0() #closest
signal zoom_step_1() #middle
signal zoom_step_2() #farthest
signal camera_pan_started()
signal structure_state_changed()
signal construction_button_mouse_entered()
signal tutorial_skipped()

const tutorial_data_file_path = "res://assets/data/tutorial.json"


onready var _tween := $Tween

var _tutorial_active := true
var _allowed_structure_type_id := -1
var _structure_state_changed_map_cell := Vector2.INF
var _tutorial_skipped := false
var _tutorial_action_signal_counts := {}

func _enter_tree():
	ServiceMgr.register_service(TutorialMgr, self)


func _ready():
	SignalMgr.register_publisher(self, "ToggleNoMusic")
	SignalMgr.register_publisher(self, "HighlightConstructionButton")
	SignalMgr.register_publisher(self, "BlinkConstructionButtonHighlight")
	SignalMgr.register_publisher(self, "TutorialComplete")

	SignalMgr.register_publisher(self, "highlight_ore_display")
	SignalMgr.register_publisher(self, "hide_ore_display_highlight")
	SignalMgr.register_publisher(self, "highlight_total_power")
	SignalMgr.register_publisher(self, "hide_total_power_highlight")
	SignalMgr.register_publisher(self, "highlight_power_needed")
	SignalMgr.register_publisher(self, "hide_powered_needed_highlight")
	SignalMgr.register_publisher(self, "highlight_population")
	SignalMgr.register_publisher(self, "hide_population_highlight")
	SignalMgr.register_publisher(self, "highlight_harvester_launch_button")
	SignalMgr.register_publisher(self, "hide_harvester_launch_button_highlight")
	SignalMgr.register_publisher(self, "highlight_construction_buttons")
	SignalMgr.register_publisher(self, "hide_construction_buttons_highlight")
	SignalMgr.register_publisher(self, "extend_construction_drawer")
	SignalMgr.register_publisher(self, "retract_construction_drawer")
	SignalMgr.register_publisher(self, "highlight_construction_drawer")
	SignalMgr.register_publisher(self, "hide_construction_drawer_highlight")
	SignalMgr.register_publisher(self, "enable_structure_tile_tooltip")
	SignalMgr.register_publisher(self, "disable_structure_tile_tooltip")

	SignalMgr.register_subscriber(self, "zoom_step_change_initiated", "_on_zoom_step_change_initiated")
	SignalMgr.register_subscriber(self, "camera_pan_started", "_on_camera_pan_started")
	SignalMgr.register_subscriber(self, "structure_state_changed", "_on_structure_state_changed")
	SignalMgr.register_subscriber(self, "tutorial_skipped", "_on_tutorial_skipped")
	SignalMgr.register_subscriber(self, "construction_button_mouse_entered")
	CameraShake.enable_camera_shake(self)
	call_deferred("_do_tutorial")


func _init_for_tutorial():
	var time_line: TimeLine = ServiceMgr.get_service(TimeLine)
	time_line.deactivate()
	time_line.exhaust_length_percent = 0.0
	var damage_mgr: DamageMgr = ServiceMgr.get_service(DamageMgr)
	damage_mgr.deactivate()
	var game_background: GameBackground = ServiceMgr.get_service(GameBackground)
	game_background.speed = 0.0
	var moon: Moon = ServiceMgr.get_service(Moon)
	moon.exhaust_length_percent = 0.0
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	structure_mgr.disable_enable_allowed = false
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	resource_mgr.reclamation_enabled = false
	disable_structure_tile_tooltip()

func _init_for_launch():
	emit_signal("TutorialComplete")
	var time_line: TimeLine = ServiceMgr.get_service(TimeLine)
	time_line.exhaust_length_percent = 0.0
	var game_background: GameBackground = ServiceMgr.get_service(GameBackground)
	game_background.speed = 0.0
	var moon: Moon = ServiceMgr.get_service(Moon)
	moon.exhaust_length_percent = 0.0



func _end_tutorial():
	_tutorial_active = false
	HudAlertsMgr.add_hud_alert("Launching moon!")
	yield(get_tree().create_timer(3.0), "timeout")
	HudAlertsMgr.add_hud_alert("Impossible drive engaged.")
	yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("ToggleNoMusic", false)
	var time_line: TimeLine = ServiceMgr.get_service(TimeLine)
	time_line.activate()
	var damage_mgr: DamageMgr = ServiceMgr.get_service(DamageMgr)
	damage_mgr.activate()
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	structure_mgr.disable_enable_allowed = true
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	resource_mgr.reclamation_enabled = true
	enable_structure_tile_tooltip()

	var game_background: GameBackground = ServiceMgr.get_service(GameBackground)
	var moon: Moon = ServiceMgr.get_service(Moon)
	CameraShake.shake_camera(self, 1, 5.0, 50.0)
	_tween.interpolate_property(game_background, "speed", 0.0, 10.0, 5.0)
	_tween.interpolate_property(moon, "exhaust_length_percent", 0.0, 1.0, 5.0)
	_tween.interpolate_property(time_line, "exhaust_length_percent", 0.0, 1.0, 5.0)
	_tween.start()
	

func _do_tutorial():
	if Settings.is_tutorial_finished():
		_init_for_launch()
		_end_tutorial()
		return

	_init_for_tutorial()

	var wait_time := 2.0
	var section_pause_time := 1.0
	var yield_util := YieldUtil.new()
	yield_util.add(self, "tutorial_skipped")
	
	var tutorial_data := FileUtil.load_json_data(tutorial_data_file_path)
	"""
	Tutorial data is an array of arrays.  
	Each array consists of strings and there may be a number in the last position.
	Each string that is not the last string is a line of tutorial dialog if it doesn't begin with FuncRef:
	If the string begins with FuncRef: then this prefix is removed and the named function is called
	If the string is the last string, then it denotes a signal to wait for or to show the Continue button.
	If there's a number in the last position, then it indicates the number of times to wait for the signal.
	"""
	
	for tutorial_part in tutorial_data:
		if _tutorial_skipped:
			break
		
		var tutorial_part_size:int = tutorial_part.size()
		var repeat_yield := 1
		var last_entry = tutorial_part[tutorial_part_size - 1]
		if last_entry is float:
			tutorial_part_size -= 1
			repeat_yield = int(last_entry)
		#_tutorial_action_signal_counts.erase(tutorial_part[tutorial_part_size-1])
		
		for i in range(tutorial_part_size):
			if _tutorial_skipped:
				break
			
			var tutorial_line:String = tutorial_part[i]
			if tutorial_line.begins_with("FuncRef:"):
				var func_name = tutorial_line.replace("FuncRef:", "")
				var func_ref := funcref(self, func_name)
				func_ref.call_func()
				continue
			
			if i + 1 == tutorial_part_size:
				if tutorial_line == "Continue":
					yield_util.add(HudAlertsMgr.add_continue_and_wait())
					yield(yield_util.wait_any(), "completed")
					HudAlertsMgr.clear_hud_alerts()
					yield(get_tree().create_timer(section_pause_time), "timeout")
				else:
					if _tutorial_action_signal_counts.has(tutorial_line):
						if _tutorial_action_signal_counts[tutorial_line] >= repeat_yield:
							HudAlertsMgr.clear_hud_alerts()
							continue
					yield_util.add(self, tutorial_line)
					for _i in range(repeat_yield):
						yield(yield_util.wait_any(), "completed")
						if _tutorial_skipped:
							break
						if _tutorial_action_signal_counts.has(tutorial_line):
							if _tutorial_action_signal_counts[tutorial_line] >= repeat_yield:
								continue
					HudAlertsMgr.clear_hud_alerts()
					if !_tutorial_skipped:
						yield(get_tree().create_timer(section_pause_time), "timeout")
					yield_util.remove(self, tutorial_line)
			else:
				HudAlertsMgr.add_hud_alert(tutorial_line, true)
				yield(get_tree().create_timer(wait_time), "timeout")

	HudAlertsMgr.clear_hud_alerts()
	_init_for_launch()
	_end_tutorial()
	Settings.mark_tutorial_finished()

func _record_tutorial_signal(signal_name: String) -> void:
	if _tutorial_action_signal_counts.has(signal_name):
		_tutorial_action_signal_counts[signal_name] += 1
	else:
		_tutorial_action_signal_counts[signal_name] = 1


func damage_random_structure():
	var damage_mgr: DamageMgr = ServiceMgr.get_service(DamageMgr)
	damage_mgr.damage_random_structure()
	_tutorial_action_signal_counts.erase("structure_state_changed")


func is_construction_allowed(structure_type_id: int) -> bool:
	if !_tutorial_active:
		return true
	return structure_type_id == _allowed_structure_type_id


func _on_zoom_step_change_initiated(from_zoom_step: int, to_zoom_step: int, zoom_speed: float) -> void:
	if to_zoom_step == 0:
		_record_tutorial_signal("zoom_step_0")
		emit_signal("zoom_step_0")
	if to_zoom_step == 1:
		_record_tutorial_signal("zoom_step_1")
		emit_signal("zoom_step_1")
	if to_zoom_step == 2:
		_record_tutorial_signal("zoom_step_2")
		emit_signal("zoom_step_2")

func _on_camera_pan_started():
	_record_tutorial_signal("camera_pan_started")
	emit_signal("camera_pan_started")


func _on_structure_state_changed(structure_map_cell):
	_structure_state_changed_map_cell = structure_map_cell
	_record_tutorial_signal("structure_state_changed")
	emit_signal("structure_state_changed")

func _is_structure_repaired(structure_map_cell):
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	var structure_data := structure_mgr.get_structure(structure_map_cell)
	return !structure_data.damaged

func _on_tutorial_skipped():
	_tutorial_skipped = true
	_record_tutorial_signal("tutorial_skipped")
	emit_signal("tutorial_skipped")


func _on_construction_button_mouse_entered(structure_type_id) -> void:
	_record_tutorial_signal("construction_button_mouse_entered")
	emit_signal("construction_button_mouse_entered")


func highlight_ore_display():
	emit_signal("highlight_ore_display")


func hide_ore_display_highlight():
	emit_signal("hide_ore_display_highlight")


func highlight_harvester_launch_button():
	emit_signal("highlight_harvester_launch_button")


func hide_harvester_launch_button_highlight():
	emit_signal("hide_harvester_launch_button_highlight")


func highlight_timeline():
	var time_line: TimeLine = ServiceMgr.get_service(TimeLine)
	time_line.show_highlight()


func hide_timeline_highlight():
	var time_line: TimeLine = ServiceMgr.get_service(TimeLine)
	time_line.hide_highlight()


func highlight_total_power():
	emit_signal("highlight_total_power")


func hide_total_power_highlight():
	emit_signal("hide_total_power_highlight")


func highlight_power_needed():
	emit_signal("highlight_power_needed")


func hide_powered_needed_highlight():
	emit_signal("hide_powered_needed_highlight")


func highlight_population():
	emit_signal("highlight_population")


func hide_population_highlight():
	emit_signal("hide_population_highlight")


func highlight_construction_buttons():
	emit_signal("highlight_construction_buttons")


func hide_construction_buttons_highlight():
	print("TutorialMgr: emitting hide_construction_buttons_highlight")
	emit_signal("hide_construction_buttons_highlight")


func extend_construction_drawer():
	emit_signal("extend_construction_drawer")


func retract_construction_drawer():
	emit_signal("retract_construction_drawer")


func highlight_construction_drawer():
	emit_signal("highlight_construction_drawer")


func hide_construction_drawer_highlight():
	emit_signal("hide_construction_drawer_highlight")


func enable_structure_tile_tooltip():
	emit_signal("enable_structure_tile_tooltip")


func disable_structure_tile_tooltip():
	emit_signal("disable_structure_tile_tooltip")



