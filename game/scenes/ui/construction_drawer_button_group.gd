extends VBoxContainer

signal construction_tool_bar_clicked(structure_tile_type)
signal construction_button_mouse_entered(structure_type)
signal construction_button_mouse_exited(structure_type)

export (StructureMgr.StructureTileType) var structure_type: int

var shortcut: ShortCut

onready var _texture_button := $Panel/MarginContainer/TextureButton
onready var _short_name_label := $ShortNameLabel
onready var _cost_label := $CostLabel
onready var _functional_label := $FunctionalLabel
onready var _population_supported_label := $PopulationSupportedLabel
onready var _population_possible_label := $PopulationPossibleLabel
onready var _mouse_over_sound := $MouseOverStreamPlayer
onready var _shortcut_label := $Panel/MarginContainer/TextureButton/ShortcutLabel
onready var _highlight_texture := $Panel/MarginContainer/TextureButton/HighlightTextureRect

var _normal_icons := {
	StructureMgr.StructureTileType.Agriculture: "res://assets/images/ui/icons/Agriculture_icon.png",
	StructureMgr.StructureTileType.Education: "res://assets/images/ui/icons/Education_icon.png",
	StructureMgr.StructureTileType.Factory: "res://assets/images/ui/icons/Factory_icon.png",
	StructureMgr.StructureTileType.Medical: "res://assets/images/ui/icons/Medical_icon.png",
	StructureMgr.StructureTileType.Office: "res://assets/images/ui/icons/Office_icon.png",
	StructureMgr.StructureTileType.Power: "res://assets/images/ui/icons/Power_Reactor_icon.png",
	StructureMgr.StructureTileType.Reclamation: "res://assets/images/ui/icons/Reclaimation-Center_icon.png",
	StructureMgr.StructureTileType.Recreation: "res://assets/images/ui/icons/Recreation_icon.png",
	StructureMgr.StructureTileType.Residential: "res://assets/images/ui/icons/Residence_icon.png",
	StructureMgr.StructureTileType.UUC: "res://assets/images/ui/icons/Start-Tile_icon.png",
}

var _disabled_icons := {
	StructureMgr.StructureTileType.Agriculture: "res://assets/images/ui/icons/Agriculture_icon_disabled.png",
	StructureMgr.StructureTileType.Education: "res://assets/images/ui/icons/Education_icon_disabled.png",
	StructureMgr.StructureTileType.Factory: "res://assets/images/ui/icons/Factory_icon_disabled.png",
	StructureMgr.StructureTileType.Medical: "res://assets/images/ui/icons/Medical_icon_disabled.png",
	StructureMgr.StructureTileType.Office: "res://assets/images/ui/icons/Office_icon_disabled.png",
	StructureMgr.StructureTileType.Power: "res://assets/images/ui/icons/Power_Reactor_icon_disabled.png",
	StructureMgr.StructureTileType.Reclamation: "res://assets/images/ui/icons/Reclaimation-Center_icon_disabled.png",
	StructureMgr.StructureTileType.Recreation: "res://assets/images/ui/icons/Recreation_icon_disabled.png",
	StructureMgr.StructureTileType.Residential: "res://assets/images/ui/icons/Residence_icon_disabled.png",
	StructureMgr.StructureTileType.UUC: "res://assets/images/ui/icons/Start-Tile_icon_disabled.png",
}

func _ready():
	SignalMgr.register_publisher(self, "construction_tool_bar_clicked")
	SignalMgr.register_publisher(self, "construction_button_mouse_entered")
	SignalMgr.register_publisher(self, "construction_button_mouse_exited")
	SignalMgr.register_subscriber(self, "resources_updated", "_on_resources_updated")
	SignalMgr.register_subscriber(self, "structure_state_changed", "_on_structure_state_changed")
	
	_texture_button.texture_normal = load(_normal_icons[structure_type])
	_texture_button.texture_disabled = load(_disabled_icons[structure_type])
	#_texture_button.hint_tooltip = EnumUtil.get_string(StructureMgr.StructureTileType, structure_type)
	_highlight_texture.visible = false
	
	
	call_deferred("_init_labels")


func _init_labels():
	var structure_mgr :StructureMgr = ServiceMgr.get_service(StructureMgr)
	var structure_metadata := structure_mgr.get_structure_metadata(structure_type)
	var short_cut_key = structure_metadata.get_construction_short_cut_key()
	var scancode = ord(short_cut_key)
	
	shortcut = ShortCut.new()
	var inputEventKey := InputEventKey.new()
	inputEventKey.scancode = scancode
	inputEventKey.pressed = true
	shortcut.shortcut = inputEventKey
	_texture_button.shortcut = shortcut
	var shortcut_string = "(%s)" % short_cut_key # char(inputEventKey.scancode)
	_shortcut_label.text = shortcut_string

	var construction_cost_string = _make_resources_string(structure_metadata.get_construction_resources(), "-")
	_cost_label.text = construction_cost_string
	_short_name_label.text = structure_metadata.get_short_name()
	#_texture_button.hint_tooltip = structure_metadata.get_name()
	_update_labels()


func _make_resources_string(resources: Dictionary, amount_prefix: String) -> String:
	var s = ""
	for resource_name in resources.keys():
		if s.length() > 0:
			s += ", "
		s += amount_prefix + str(int(resources[resource_name])) + " " + resource_name
	return s


func _on_TextureButton_mouse_entered():
	_mouse_over_sound.play()
	_highlight_texture.visible = true
	emit_signal("construction_button_mouse_entered", structure_type)


func _on_TextureButton_pressed():
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	if resource_mgr.have_enough_resources_for_constructions(structure_type):
		emit_signal("construction_tool_bar_clicked", structure_type)
		#_menu_select_sound.play()
		#_skip_next_menu_select_sound = true
	else:
		var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
		var structure_metadata := structure_mgr.get_structure_metadata(structure_type)
		HudAlertsMgr.add_hud_alert("Not enough resources to construct %s " % structure_metadata.get_name())


func _on_TextureButton_mouse_exited():
	_highlight_texture.visible = false
	emit_signal("construction_button_mouse_exited", structure_type)

func _on_resources_updated():
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	if resource_mgr == null:
		return
	_texture_button.disabled = !resource_mgr.have_enough_resources_for_constructions(structure_type)

func _update_labels() -> void:
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	var structure_metadata := structure_mgr.get_structure_metadata(structure_type)
	var structure_name = structure_metadata.get_name()
	var short_cut_key = structure_metadata.get_construction_short_cut_key()
	var structures = structure_mgr.get_structures_by_type_id(structure_type)
	var total = structures.size()
	var functioning_structures = structure_mgr.get_functioning_structures_by_type_id(structure_type)
	var functioning = functioning_structures.size()
	_functional_label.text = "%d/%d" % [functioning, total]
	
	var stats_mgr: StatsMgr = ServiceMgr.get_service(StatsMgr)
	var stat := stats_mgr.get_stat_provided_by_structure_type_id(structure_type)
	if stat != null && stat.has_population_schedule():
		var units_per_structure := stat.get_units_per_structure()
		var total_population_provided = functioning * units_per_structure
		var population_currently_supported = stats_mgr.calc_structure_produced_stats(stat, functioning_structures)
		#_population_label.text =  "%d/%d" % [population_currently_supported, total_population_provided]
		_population_supported_label.text = "%d" % population_currently_supported
		_population_possible_label.text = "%d" % total_population_provided
	
	


func _on_structure_state_changed(tile_map_cell: Vector2) -> void:
	_update_labels()

