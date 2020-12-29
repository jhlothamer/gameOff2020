extends CanvasLayer

signal focused_gained(control)
signal reclaim_structure_initiated()
signal random_damage_test_clicked()
signal harvester_activated()

onready var dialogs: Control = $Dialogs
onready var resources_dialog: Control = $Dialogs/ResourcesDlg
onready var structures_dialog := $Dialogs/StructuresDialog
onready var help_dialog := $Dialogs/HelpDialog
onready var _help_btn := $BottomRightMarginContainer/TextureRect/MarginContainer/HBoxContainer/HelpBtn
onready var _active_harvester_animation := $BottomRightMarginContainer/TextureRect/MarginContainer/HBoxContainer/LaunchHarvesterBtn/ActiveHarvesterAnimation
onready var _launch_harvester_btn := $BottomRightMarginContainer/TextureRect/MarginContainer/HBoxContainer/LaunchHarvesterBtn

var _last_control_focused: Control

func _ready():
	SignalMgr.register_publisher(self, "focused_gained")
	SignalMgr.register_publisher(self, "reclaim_structure_initiated")
	SignalMgr.register_publisher(self, "random_damage_test_clicked")
	SignalMgr.register_publisher(self, "harvester_activated")
	SignalMgr.register_subscriber(self, "harvester_active", "_on_harvester_active")
	SignalMgr.register_subscriber(self, "harvester_inactive", "_on_harvester_inactive")
	SignalMgr.register_subscriber(self, "population_crashed_game_over", "_on_population_crashed_game_over")
	for child in dialogs.get_children():
		child.visible = false
	dialogs.visible = true
	call_deferred("_delayed_init")

func _delayed_init():
	var stat_mgr:StatsMgr = ServiceMgr.get_service(StatsMgr)
	if stat_mgr == null:
		return
	var win_population = stat_mgr.get_win_game_population_amount()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		#print("unhandled mouse button event")
		emit_signal("focused_gained", self)


func _on_ResourceDialogBtn_pressed():
	if !resources_dialog.visible:
		resources_dialog.show()
	else:
		resources_dialog.hide()


func _on_DeconstructBtn_pressed():
	emit_signal("reclaim_structure_initiated")


func _on_RndDmgTestBtn_pressed():
	emit_signal("random_damage_test_clicked")


func _on_HelpBtn_pressed():
	_help_btn.release_focus()
	help_dialog.show()


func _on_LaunchHarvesterBtn_pressed():
	emit_signal("harvester_activated")


func _on_harvester_active():
	_active_harvester_animation.play()
	_active_harvester_animation.visible = true
	_launch_harvester_btn.hint_tooltip = "Harvester Active"


func _on_harvester_inactive():
	_active_harvester_animation.stop()
	_active_harvester_animation.visible = false
	_launch_harvester_btn.hint_tooltip = "Launch Harvester"


func _on_population_crashed_game_over():
	transitionMgr.transitionTo(Constants.POP_CRASH_ENDING_SCENE_PATH, Constants.TRANSITION_SPEED, true)
