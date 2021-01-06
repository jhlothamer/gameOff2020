extends MarginContainer

export var travel_time := .25

const TRAVEL_Y = 85

onready var _tween := $Tween
onready var _open_audio := $MenuOpenAudioStream
onready var _close_audio := $MenuCloseAudioStream
onready var _select_audio := $MenuSelectAudioStream
onready var _expand_contract_btn := $HBoxContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/ExpandContractBtn
onready var _ribbon_label := $HBoxContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/ribbonLabel
onready var _animation_player_buttons := $AnimationPlayerButtons
onready var _animation_player_info_panel := $AnimationPlayerInfoPanel
onready var _full_name_label := $HBoxContainer/PanelContainer/VBoxContainer/InfoPanel/MarginContainer/PanelContainer/VBoxContainer/FullNameLabel
onready var _description_label := $HBoxContainer/PanelContainer/VBoxContainer/InfoPanel/MarginContainer/PanelContainer/VBoxContainer/Description

var _tween_trans := Tween.TRANS_EXPO
var _current_hover_structure_type_id := -1

func _ready():
	SignalMgr.register_subscriber(self, "construction_tool_bar_clicked", "_on_construction_tool_bar_clicked")
	SignalMgr.register_subscriber(self, "construction_button_mouse_entered", "_on_construction_button_mouse_entered")
	SignalMgr.register_subscriber(self, "construction_button_mouse_exited", "_on_construction_button_mouse_exited")
	SignalMgr.register_subscriber(self, "structure_state_changed", "_on_structure_state_changed")
	SignalMgr.register_subscriber(self, "highlight_construction_buttons")
	SignalMgr.register_subscriber(self, "hide_construction_buttons_highlight")
	SignalMgr.register_subscriber(self, "extend_construction_drawer")
	SignalMgr.register_subscriber(self, "retract_construction_drawer")
	SignalMgr.register_subscriber(self, "highlight_construction_drawer")
	SignalMgr.register_subscriber(self, "hide_construction_drawer_highlight")

func _on_construction_tool_bar_clicked(structure_tile_type):
	_select_audio.play()
	if _expand_contract_btn.pressed:
		_expand_contract_btn.pressed = false


func _on_ExpandContractBtn_toggled(button_pressed):
	if button_pressed:
		_expand_menu()
	else:
		_contract_menu()

func _expand_menu():
	if _tween.is_active():
		_tween.stop_all()
	_tween.interpolate_property(self, "rect_position", rect_position, rect_position + Vector2.UP*TRAVEL_Y, travel_time, _tween_trans, Tween.EASE_IN_OUT)
	_tween.start()
	_open_audio.play()

func _contract_menu():
	if _tween.is_active():
		_tween.stop_all()
	_tween.interpolate_property(self, "rect_position", rect_position, rect_position + Vector2.DOWN*TRAVEL_Y, travel_time, _tween_trans, Tween.EASE_IN_OUT)
	_tween.start()
	if !_select_audio.playing:
		_close_audio.play()

func _on_construction_button_mouse_entered(structure_type_id):
	_current_hover_structure_type_id = structure_type_id
	_update_ribbon_text(structure_type_id)

func _on_construction_button_mouse_exited(structure_type_id):
	_current_hover_structure_type_id = -1
	_ribbon_label.text = ""
	_full_name_label.text = "Mouse over a button for more information"
	_description_label.text = ""
	


func _update_ribbon_text(structure_type_id: int) -> void:
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	var structure_metadata := structure_mgr.get_structure_metadata(structure_type_id)
	var structure_name = structure_metadata.get_name()
	var short_cut_key = structure_metadata.get_construction_short_cut_key()
	var structures = structure_mgr.get_structures_by_type_id(structure_type_id)
	var total = structures.size()
	var functioning_structures = structure_mgr.get_functioning_structures_by_type_id(structure_type_id)
	var functioning = functioning_structures.size()
	var label = "%s (%s) functional: %d/%d" % [structure_name, short_cut_key, functioning, total]
	_full_name_label.text = structure_name + " (%s)" % structure_metadata.get_construction_resources_string()
	_description_label.text = structure_metadata.get_description()
	
	
	var stats_mgr: StatsMgr = ServiceMgr.get_service(StatsMgr)
	var stat := stats_mgr.get_stat_provided_by_structure_type_id(structure_type_id)
	if stat != null && stat.has_population_schedule():
		var units_per_structure := stat.get_units_per_structure()
		var total_population_provided = functioning * units_per_structure
		var population_currently_supported = stats_mgr.calc_structure_produced_stats(stat, functioning_structures)
		label += " population: %d/%d" % [population_currently_supported, total_population_provided]
	
	_ribbon_label.text = label


func _on_structure_state_changed(tile_map_cell: Vector2) -> void:
	if _current_hover_structure_type_id < 0:
		return
	_update_ribbon_text(_current_hover_structure_type_id)


func _on_highlight_construction_buttons():
	_animation_player_buttons.play("show buttons highlight", -1, .3)


func _on_hide_construction_buttons_highlight():
	print("ConstructionDrawer: received signal hide_construction_buttons_highlight")
	_animation_player_buttons.play("hide buttons highlight")


func _on_extend_construction_drawer():
	_expand_contract_btn.pressed = true


func _on_retract_construction_drawer():
	_expand_contract_btn.pressed = false


func _on_highlight_construction_drawer():
	_animation_player_info_panel.play("show info panel highlight", -1, .3)


func _on_hide_construction_drawer_highlight():
	_animation_player_info_panel.play("hide info panel highlight")
