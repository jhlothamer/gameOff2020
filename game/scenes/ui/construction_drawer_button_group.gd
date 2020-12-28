extends VBoxContainer

signal construction_tool_bar_clicked(structure_tile_type)
signal construction_button_mouse_entered(structure_type)
signal construction_button_mouse_exited(structure_type)

export (StructureMgr.StructureTileType) var structure_type: int

var disabled := false setget _set_disabled
var collapsed := true setget _set_collapsed
var shortcut: ShortCut

onready var _texture_button := $Panel/MarginContainer/TextureButton
onready var _short_name_label := $ShortNameLabel
onready var _cost_label := $CostLabel
onready var _mouse_over_sound := $MouseOverStreamPlayer
onready var _shortcut_label := $Panel/MarginContainer/TextureButton/ShortcutLabel
onready var _highlight_texture := $Panel/MarginContainer/TextureButton/HighlightTextureRect

var _normal_icons := {
	StructureMgr.StructureTileType.Agriculture: "res://assets/images/ui/icons/Agriculture_icon.png",
	Constants.StructureTileType.Education: "res://assets/images/ui/icons/Education_icon.png",
	Constants.StructureTileType.Factory: "res://assets/images/ui/icons/Factory_icon.png",
	Constants.StructureTileType.Medical: "res://assets/images/ui/icons/Medical_icon.png",
	Constants.StructureTileType.Office: "res://assets/images/ui/icons/Office_icon.png",
	Constants.StructureTileType.Power: "res://assets/images/ui/icons/Power_Reactor_icon.png",
	Constants.StructureTileType.Reclamation: "res://assets/images/ui/icons/Reclaimation-Center_icon.png",
	Constants.StructureTileType.Recreation: "res://assets/images/ui/icons/Recreation_icon.png",
	Constants.StructureTileType.Residential: "res://assets/images/ui/icons/Residence_icon.png",
	Constants.StructureTileType.UUC: "res://assets/images/ui/icons/Start-Tile_icon.png",
}

var _disabled_icons := {
	StructureMgr.StructureTileType.Agriculture: "res://assets/images/ui/icons/Agriculture_icon_disabled.png",
	Constants.StructureTileType.Education: "res://assets/images/ui/icons/Education_icon_disabled.png",
	Constants.StructureTileType.Factory: "res://assets/images/ui/icons/Factory_icon_disabled.png",
	Constants.StructureTileType.Medical: "res://assets/images/ui/icons/Medical_icon_disabled.png",
	Constants.StructureTileType.Office: "res://assets/images/ui/icons/Office_icon_disabled.png",
	Constants.StructureTileType.Power: "res://assets/images/ui/icons/Power_Reactor_icon_disabled.png",
	Constants.StructureTileType.Reclamation: "res://assets/images/ui/icons/Reclaimation-Center_icon_disabled.png",
	Constants.StructureTileType.Recreation: "res://assets/images/ui/icons/Recreation_icon_disabled.png",
	Constants.StructureTileType.Residential: "res://assets/images/ui/icons/Residence_icon_disabled.png",
	Constants.StructureTileType.UUC: "res://assets/images/ui/icons/Start-Tile_icon_disabled.png",
}

func _ready():
	SignalMgr.register_publisher(self, "construction_tool_bar_clicked")
	SignalMgr.register_publisher(self, "construction_button_mouse_entered")
	SignalMgr.register_publisher(self, "construction_button_mouse_exited")
	
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


func _make_resources_string(resources: Dictionary, amount_prefix: String) -> String:
	var s = ""
	for resource_name in resources.keys():
		if s.length() > 0:
			s += ", "
		s += amount_prefix + str(int(resources[resource_name])) + " " + resource_name
	return s

func _set_disabled(value):
	disabled = value
	if _texture_button != null:
		_texture_button.disabled = value


func _set_collapsed(value):
	collapsed = value
	visible = !collapsed


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
