extends CanvasLayer

signal focused_gained(control)
signal reclaim_structure_initiated()
signal random_damage_test_clicked()
signal harvester_activated()
signal tutorial_skipped()

onready var dialogs: Control = $Dialogs
onready var resources_dialog: Control = $Dialogs/ResourcesDlg
onready var structures_dialog := $Dialogs/StructuresDialog
onready var help_dialog := $Dialogs/HelpDialog
onready var _help_btn := $BottomRightMarginContainer/VBoxContainer/TextureRect/MarginContainer/HBoxContainer/HelpBtn
onready var _active_harvester_animation := $BottomRightMarginContainer/VBoxContainer/TextureRect/MarginContainer/HBoxContainer/LaunchHarvesterBtn/ActiveHarvesterAnimation
onready var _launch_harvester_btn := $BottomRightMarginContainer/VBoxContainer/TextureRect/MarginContainer/HBoxContainer/LaunchHarvesterBtn

onready var _population_stat_display := $BottomLeftMarginContainer/TextureRect/MarginContainer/VBoxContainer/PopulationStatDisplay
onready var _power_stat_display := $BottomLeftMarginContainer/TextureRect/MarginContainer/VBoxContainer/PowerStatDisplay
onready var _power_required_stat_display := $BottomLeftMarginContainer/TextureRect/MarginContainer/VBoxContainer/PowerRequiredStatDisplay
onready var _ore_stat_display := $BottomLeftMarginContainer/TextureRect/MarginContainer/VBoxContainer/OreStatDisplay
onready var _animation_player := $AnimationPlayer
onready var _skip_tutorial_btn := $BottomRightMarginContainer/VBoxContainer/SkipTutorialBtn

var _last_control_focused: Control

func _ready():
	SignalMgr.register_publisher(self, "focused_gained")
	SignalMgr.register_publisher(self, "reclaim_structure_initiated")
	SignalMgr.register_publisher(self, "random_damage_test_clicked")
	SignalMgr.register_publisher(self, "harvester_activated")
	SignalMgr.register_subscriber(self, "harvester_active", "_on_harvester_active")
	SignalMgr.register_subscriber(self, "harvester_inactive", "_on_harvester_inactive")
	SignalMgr.register_subscriber(self, "population_crashed_game_over", "_on_population_crashed_game_over")
	SignalMgr.register_publisher(self, "tutorial_skipped")
	SignalMgr.register_subscriber(self, "highlight_ore_display")
	SignalMgr.register_subscriber(self, "hide_ore_display_highlight")
	SignalMgr.register_subscriber(self, "highlight_total_power")
	SignalMgr.register_subscriber(self, "hide_total_power_highlight")
	SignalMgr.register_subscriber(self, "highlight_power_needed")
	SignalMgr.register_subscriber(self, "hide_powered_needed_highlight")
	SignalMgr.register_subscriber(self, "highlight_population")
	SignalMgr.register_subscriber(self, "hide_population_highlight")
	SignalMgr.register_subscriber(self, "highlight_harvester_launch_button")
	SignalMgr.register_subscriber(self, "hide_harvester_launch_button_highlight")
	SignalMgr.register_subscriber(self, "TutorialComplete")

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


func _on_SkipTutorialBtn_pressed():
	emit_signal("tutorial_skipped")


func _on_highlight_ore_display():
	_ore_stat_display.show_highlight()


func _on_hide_ore_display_highlight():
	_ore_stat_display.hide_highlight()


func _on_highlight_total_power():
	_power_stat_display.show_highlight()


func _on_hide_total_power_highlight():
	_power_stat_display.hide_highlight()


func _on_highlight_power_needed():
	_power_required_stat_display.show_highlight()


func _on_hide_powered_needed_highlight():
	_power_required_stat_display.hide_highlight()


func _on_highlight_population():
	_population_stat_display.show_highlight()


func _on_hide_population_highlight():
	_population_stat_display.hide_highlight()


func _on_highlight_harvester_launch_button():
	_animation_player.play("show launch harvester highlight", -1, .3)


func _on_hide_harvester_launch_button_highlight():
	_animation_player.play("hide launch harvester highlight")

func _on_TutorialComplete():
	_skip_tutorial_btn.self_modulate = Color(1,1,1,0)
