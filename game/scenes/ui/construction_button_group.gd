extends Panel

signal button_down()
signal shortcut_activated()
signal construction_button_mouse_entered(structure_type)
signal construction_button_mouse_exited(structure_type)

export (StructureMgr.StructureTileType) var structure_type: int

var disabled := false setget _set_disabled
var collapsed := true setget _set_collapsed
var label_visible := false setget _set_label_visible
var shortcut: ShortCut

onready var _texture_button := $PanelContainer/VBoxContainer/TextureButton
onready var _label := $PanelContainer/VBoxContainer/Label
onready var _mouse_over_sound := $MouseOverStreamPlayer
onready var _shortcut_label = $PanelContainer/VBoxContainer/TextureButton/ShortcutLabel

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

var _mouse_over_icons := {
	StructureMgr.StructureTileType.Agriculture: "res://assets/images/ui/icons/Agriculture_icon_mouse_over.png",
	StructureMgr.StructureTileType.Education: "res://assets/images/ui/icons/Education_icon_mouse_over.png",
	StructureMgr.StructureTileType.Factory: "res://assets/images/ui/icons/Factory_icon_mouse_over.png",
	StructureMgr.StructureTileType.Medical: "res://assets/images/ui/icons/Medical_icon_mouse_over.png",
	StructureMgr.StructureTileType.Office: "res://assets/images/ui/icons/Office_icon_mouse_over.png",
	StructureMgr.StructureTileType.Power: "res://assets/images/ui/icons/Power_Reactor_icon_mouse_over.png",
	StructureMgr.StructureTileType.Reclamation: "res://assets/images/ui/icons/Reclaimation-Center_icon_mouse_over.png",
	StructureMgr.StructureTileType.Recreation: "res://assets/images/ui/icons/Recreation_icon_mouse_over.png",
	StructureMgr.StructureTileType.Residential: "res://assets/images/ui/icons/Residence_icon_mouse_over.png",
	StructureMgr.StructureTileType.UUC: "res://assets/images/ui/icons/Start-Tile_icon_mouse_over.png",
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

var _shortcut_keys := {
	StructureMgr.StructureTileType.Agriculture: KEY_G,
	StructureMgr.StructureTileType.Education: KEY_E,
	StructureMgr.StructureTileType.Factory: KEY_F,
	StructureMgr.StructureTileType.Medical: KEY_M,
	StructureMgr.StructureTileType.Office: KEY_O,
	StructureMgr.StructureTileType.Power: KEY_P,
	StructureMgr.StructureTileType.Reclamation: KEY_R,
	StructureMgr.StructureTileType.Recreation: KEY_C,
	StructureMgr.StructureTileType.Residential: KEY_T,
	StructureMgr.StructureTileType.UUC: KEY_U,
}


func _ready():
#signal construction_button_mouse_entered(structure_type)
#signal construction_button_mouse_exited(structure_type)
	SignalMgr.register_publisher(self, "construction_button_mouse_entered")
	SignalMgr.register_publisher(self, "construction_button_mouse_exited")

	_texture_button.texture_normal = load(_normal_icons[structure_type])
	_texture_button.texture_hover = load(_mouse_over_icons[structure_type])
	_texture_button.texture_disabled = load(_disabled_icons[structure_type])
	_texture_button.hint_tooltip = EnumUtil.get_string(StructureMgr.StructureTileType, structure_type)
	
	shortcut = ShortCut.new()
	var inputEventKey := InputEventKey.new()
	inputEventKey.scancode = _shortcut_keys[structure_type]
	inputEventKey.pressed = true
	shortcut.shortcut = inputEventKey
	_texture_button.shortcut = shortcut
	
	var shortcut_string = "(%s)" % char(inputEventKey.scancode)
	_shortcut_label.text = shortcut_string
	
	call_deferred("_init_labels")


func _init_labels():
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	if structure_mgr == null:
		return
	var structure_metadata: StructureMgr.StructureMetadata = structure_mgr.get_structure_metadata(structure_type)
	var construction_cost_string = _make_resources_string(structure_metadata.get_construction_resources(), "-")
	_label.text = construction_cost_string
	_texture_button.hint_tooltip = structure_metadata.get_name()


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

func _set_label_visible(value):
	label_visible = value
	if _label != null:
		_label.visible = value

func _set_collapsed(value):
	collapsed = value
	visible = !collapsed

func _on_TextureButton_button_down():
	emit_signal("button_down")



func _on_TextureButton_mouse_entered():
	if !disabled && !collapsed:
		_mouse_over_sound.play()
		emit_signal("mouse_entered")
		emit_signal("construction_button_mouse_entered", structure_type)


func _unhandled_input(event):
	if !event is InputEventKey:
		return
	if event.is_echo() || !event.is_pressed():
		return
	var inputEventKey: InputEventKey = event
	if inputEventKey.scancode == shortcut.shortcut.scancode:
		emit_signal("shortcut_activated")


func _on_TextureButton_mouse_exited():
	emit_signal("mouse_exited")
	emit_signal("construction_button_mouse_exited", structure_type)
