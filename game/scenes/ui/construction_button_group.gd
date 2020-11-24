extends VBoxContainer

signal button_down()

export (StructureMgr.StructureTileType) var structure_type: int

var disabled := false setget _set_disabled
var collapsed := true
var label_visible := false setget _set_label_visible

onready var _texture_button := $TextureButton
onready var _label := $Label
onready var _mouse_over_sound := $MouseOverStreamPlayer

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

var _mouse_over_icons := {
	StructureMgr.StructureTileType.Agriculture: "res://assets/images/ui/icons/Agriculture_icon_mouse_over.png",
	Constants.StructureTileType.Education: "res://assets/images/ui/icons/Education_icon_mouse_over.png",
	Constants.StructureTileType.Factory: "res://assets/images/ui/icons/Factory_icon_mouse_over.png",
	Constants.StructureTileType.Medical: "res://assets/images/ui/icons/Medical_icon_mouse_over.png",
	Constants.StructureTileType.Office: "res://assets/images/ui/icons/Office_icon_mouse_over.png",
	Constants.StructureTileType.Power: "res://assets/images/ui/icons/Power_Reactor_icon_mouse_over.png",
	Constants.StructureTileType.Reclamation: "res://assets/images/ui/icons/Reclaimation-Center_icon_mouse_over.png",
	Constants.StructureTileType.Recreation: "res://assets/images/ui/icons/Recreation_icon_mouse_over.png",
	Constants.StructureTileType.Residential: "res://assets/images/ui/icons/Residence_icon_mouse_over.png",
	Constants.StructureTileType.UUC: "res://assets/images/ui/icons/Start-Tile_icon_mouse_over.png",
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
	_texture_button.texture_normal = load(_normal_icons[structure_type])
	_texture_button.texture_hover = load(_mouse_over_icons[structure_type])
	_texture_button.texture_disabled = load(_disabled_icons[structure_type])
	_texture_button.hint_tooltip = EnumUtil.get_string(StructureMgr.StructureTileType, structure_type)
	call_deferred("_init_labels")


func _init_labels():
	var structure_mgr := StructureMgr.get_structure_mgr()
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


func _on_TextureButton_button_down():
	emit_signal("button_down")



func _on_TextureButton_mouse_entered():
	if !disabled && !collapsed:
		_mouse_over_sound.play()
