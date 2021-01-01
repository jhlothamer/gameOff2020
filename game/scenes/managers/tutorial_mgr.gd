extends "res://scenes/managers/tutorial_mgr_interface.gd"

signal TutorialComplete()
signal ToggleNoMusic(no_music)
signal HighlightConstructionButton(structure_type_id, highlight_flag)
signal BlinkConstructionButtonHighlight(structure_type_id)

#tutorial signals
signal zoom_step_0() #closest
signal zoom_step_1() #middle
signal zoom_step_2() #farthest
signal camera_pan_started()
signal structure_state_changed()

onready var _tween := $Tween

var _tutorial_active := true
var _allowed_structure_type_id := -1
var _structure_state_changed_map_cell := Vector2.INF

func _enter_tree():
	ServiceMgr.register_service(TutorialMgr, self)


func _ready():
	SignalMgr.register_publisher(self, "ToggleNoMusic")
	SignalMgr.register_publisher(self, "HighlightConstructionButton")
	SignalMgr.register_publisher(self, "BlinkConstructionButtonHighlight")
	SignalMgr.register_subscriber(self, "zoom_step_change_initiated", "_on_zoom_step_change_initiated")
	SignalMgr.register_subscriber(self, "camera_pan_started", "_on_camera_pan_started")
	SignalMgr.register_subscriber(self, "structure_state_changed", "_on_structure_state_changed")
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

func _init_for_launch():
	var time_line: TimeLine = ServiceMgr.get_service(TimeLine)
	time_line.exhaust_length_percent = 0.0
	var game_background: GameBackground = ServiceMgr.get_service(GameBackground)
	game_background.speed = 0.0
	var moon: Moon = ServiceMgr.get_service(Moon)
	moon.exhaust_length_percent = 0.0



func _end_tutorial():
	_tutorial_active = false
	emit_signal("ToggleNoMusic", false)
	var time_line: TimeLine = ServiceMgr.get_service(TimeLine)
	time_line.activate()
	var damage_mgr: DamageMgr = ServiceMgr.get_service(DamageMgr)
	damage_mgr.activate()
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	structure_mgr.disable_enable_allowed = true
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	resource_mgr.reclamation_enabled = true

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
	
	#tutorial intro
	HudAlertsMgr.add_hud_alert("Welcome commander!", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("We're about to leave the solar system on our generations long trip!", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("But first let's familiarize you with the ship controls.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("To skip this tutorial anytime click Skip Tutorial.", true)	
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("Click Continue to start the tutorial.", true)	
	yield(get_tree().create_timer(wait_time), "timeout")
	yield(HudAlertsMgr.add_continue_and_wait(), "completed")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")

	#zoom in - mid range
	HudAlertsMgr.add_hud_alert("To zoom in scroll your mouse wheel up one click.", true)
	yield(self, "zoom_step_1")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")

	#zoomed in - mid range
	HudAlertsMgr.add_hud_alert("Good! This is the mid range zoom.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("Note that zooming moves view towards the mouse pointer.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("That should make navigating to areas easier.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	yield(HudAlertsMgr.add_continue_and_wait(), "completed")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")
	
	#zoom all the way in
	HudAlertsMgr.add_hud_alert("Now Scroll your mouse wheel up once more to zoom all the way in.", true)
	yield(self, "zoom_step_0")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")

	#zoomed all the way in
	HudAlertsMgr.add_hud_alert("That's better.  Now we can see all the structures in the base.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	yield(HudAlertsMgr.add_continue_and_wait(), "completed")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")

	#intro panning
	HudAlertsMgr.add_hud_alert("Now click and drag to pan the view.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("Try to make the base in view if it's not already.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	yield(self, "camera_pan_started")
	yield(self, "camera_pan_started")
	yield(self, "camera_pan_started")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")

	#explain panning a bit
	HudAlertsMgr.add_hud_alert("Moving the view this way is called panning.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("You can pan the view around at all zoom levels.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	#yield(get_tree().create_timer(10.0), "timeout")
	yield(HudAlertsMgr.add_continue_and_wait(), "completed")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")
	
	#intro repairing structures
	var damage_mgr: DamageMgr = ServiceMgr.get_service(DamageMgr)
	var damaged_structure = damage_mgr.damage_random_structure()
	HudAlertsMgr.add_hud_alert("A structure has been damaged!", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("We better fix it before leaving the solor system.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("Hover over the damaged tile till the popup window appears.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("Then click on the repair link.", true)
	yield(self, "structure_state_changed")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")
	while !_is_structure_repaired(damaged_structure.tile_map_cell):
		HudAlertsMgr.add_hud_alert("We really need that structure repaired.", true)
		yield(get_tree().create_timer(wait_time), "timeout")
		HudAlertsMgr.add_hud_alert("Hover over the damaged tile till the popup window appears.", true)
		yield(get_tree().create_timer(wait_time), "timeout")
		HudAlertsMgr.add_hud_alert("Then click on the repair link.", true)
		yield(self, "structure_state_changed")
		HudAlertsMgr.clear_hud_alerts()
		yield(get_tree().create_timer(section_pause_time), "timeout")
	
	#explain that things break and repairs will be needed
	HudAlertsMgr.add_hud_alert("Things will break down during the long journey.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("Be sure to keep on top of repairs - lives are at stake!", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("Also, repairs cost resources - ore to be exact.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("So, let's talk about resources next.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	yield(HudAlertsMgr.add_continue_and_wait(), "completed")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")


	HudAlertsMgr.add_hud_alert("Well that's all the time we have for now.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("If you need a refresher later, see the manual.", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	HudAlertsMgr.add_hud_alert("But for now buckle up and get ready for take off!", true)
	yield(get_tree().create_timer(wait_time), "timeout")
	yield(HudAlertsMgr.add_continue_and_wait(), "completed")
	HudAlertsMgr.clear_hud_alerts()
	yield(get_tree().create_timer(section_pause_time), "timeout")
	
	_end_tutorial()
	Settings.mark_tutorial_finished()

func is_construction_allowed(structure_type_id: int) -> bool:
	if !_tutorial_active:
		return true
	return structure_type_id == _allowed_structure_type_id


func _on_zoom_step_change_initiated(from_zoom_step: int, to_zoom_step: int, zoom_speed: float) -> void:
	if to_zoom_step == 0:
		emit_signal("zoom_step_0")
	if to_zoom_step == 1:
		emit_signal("zoom_step_1")
	if to_zoom_step == 2:
		emit_signal("zoom_step_2")

func _on_camera_pan_started():
	emit_signal("camera_pan_started")


func _on_structure_state_changed(structure_map_cell):
	_structure_state_changed_map_cell = structure_map_cell
	emit_signal("structure_state_changed")

func _is_structure_repaired(structure_map_cell):
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	var structure_data := structure_mgr.get_structure(structure_map_cell)
	return !structure_data.damaged
