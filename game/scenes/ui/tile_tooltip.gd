extends Control

signal tile_tooltip_mouse_entered()
signal tile_tooltip_mouse_exited()
signal tile_tooltip_auto_closed()

signal confirm_structure_tile_reclaim(structure_tile_type, cell_v)
signal structure_tile_repaired(structure_tile_type, cell_v)
signal structure_tile_disabled(structure_tile_type, cell_v)
signal structure_tile_enabled(structure_tile_type, cell_v)


var current_structure: StructureMgr.StructureData

export (String, MULTILINE) var bb_code_format_string: String = """[table=2]
[cell][img]%STRUCTURE_TILE_IMAGE%[/img] 
[/cell]
[cell][u]%STRUCTURE_NAME%[/u]\nStatus: %STRUCTURE_STATUS%\n[color=%STRUCTURE_RECLAIM_COLOR%][url=reclaim]Reclaim[/url] %STRUCTURE_RECLAIM_RESOURCES%[/color]\n[color=%STRUCTURE_REPAIR_COLOR%][url=repair]Repair[/url] %STRUCTURE_REPAIR_RESOURCES%[/color]\n[color=%ENABLE_DISABLE_COLOR%][url=enable_disable]%ENABLE_DISABLE%[/url][/color][/cell]
[table]
"""

export var debug := false

var structure_tile_normal_icons := {
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


var structure_tile_disabled_icons := {
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

onready var _rich_text_label := $TileTooltip/MarginContainer/RichTextLabel
onready var _popup := $TileTooltip

var _enable := false
const ENABLED_COLOR_STRING = "#ffffff"
const DISABLED_COLOR_STRING = "#b3b3b3"

var _direction_try_vectors := [Vector2.ZERO, Vector2(-1,-1), Vector2(-1,0), Vector2(0, -1)]
var _direction_offset := [Vector2.ONE*10, Vector2.ONE*-20, Vector2.RIGHT*20, Vector2.UP*20]

func _ready():
	#SignalMgr.register_publisher(self, "tile_tooltip_mouse_entered")
	#SignalMgr.register_publisher(self, "tile_tooltip_mouse_exited")
	SignalMgr.register_publisher(self, "tile_tooltip_auto_closed")
	SignalMgr.register_subscriber(self, "pop_tile_tooltip", "_on_pop_tile_tooltip")
	SignalMgr.register_subscriber(self, "hide_tile_tooltip", "_on_hide_tile_tooltip")
	SignalMgr.register_publisher(self, "structure_tile_repaired")
	#SignalMgr.register_publisher(self, "structure_tile_reclaimed")
	SignalMgr.register_publisher(self, "confirm_structure_tile_reclaim")
	SignalMgr.register_publisher(self, "structure_tile_disabled")
	SignalMgr.register_publisher(self, "structure_tile_enabled")
	SignalMgr.register_subscriber(self, "zoom_step_change_initiated", "_on_zoom_step_change_initiated")
	SignalMgr.register_subscriber(self, "structure_state_changed", "_on_structure_state_changed")

func popup_at(v: Vector2):
	if debug:
		print("TileTooltip: showing at location " + str(v))

	var viewport_rect := get_viewport_rect()

	var direction_offset = _direction_offset[0]
	
	#adjust v so rect is completely on screen
	for direction_try_vector in _direction_try_vectors:
		var popup_rect := Rect2(v + rect_size*direction_try_vector, rect_size)
		if viewport_rect.encloses(popup_rect):
			v = popup_rect.position
			direction_offset = _direction_offset[_direction_try_vectors.find(direction_try_vector)]
			break
	#rect_position = v - direction_offset # Vector2.ONE*10
	show()
	_popup.rect_position = v - direction_offset
	_popup.visible = true
#	var r= Rect2(v, rect_size)
#	print("TileTooltip: showing at location " + str(r))
#	popup(r)

func _on_pop_tile_tooltip(screen_coord, structure):
	if !_enable:
		return
	current_structure = structure
	_rich_text_label.bbcode_text = _get_bb_code_string()
	popup_at(screen_coord)

func _on_hide_tile_tooltip():
#	if debug:
#		print("TileTooltip: hide_tile_tooltip received")
	hide()
	_popup.hide()



func _get_structure_tile_icon_resource_path(structure: StructureMgr.StructureData):
	if structure.disabled:
		return structure_tile_disabled_icons[structure.structure_type_id]
	return structure_tile_normal_icons[structure.structure_type_id]


func _get_bb_code_string():
	var string = bb_code_format_string.replace("%STRUCTURE_TILE_IMAGE%", _get_structure_tile_icon_resource_path(current_structure))
	string = string.replace("%STRUCTURE_NAME%", current_structure.get_name())
	if current_structure.disabled:
		string = string.replace("%ENABLE_DISABLE%", "Enable")
	else:
		string = string.replace("%ENABLE_DISABLE%", "Disable")
	
	if current_structure.reclaiming:
		string = string.replace("%STRUCTURE_STATUS%", "Reclaiming")
	elif current_structure.repairing:
		string = string.replace("%STRUCTURE_STATUS%", "Repairing")
	elif current_structure.under_construction:
		string = string.replace("%STRUCTURE_STATUS%", "Constructing")
	elif current_structure.damaged:
		string = string.replace("%STRUCTURE_STATUS%", "Damaged")
	elif current_structure.lacks_resources():
		string = string.replace("%STRUCTURE_STATUS%", "Lacking " + current_structure.resources_lacking[0])
	elif current_structure.disabled:
		string = string.replace("%STRUCTURE_STATUS%", "Disabled")
	else:
		string = string.replace("%STRUCTURE_STATUS%", "Functional")
	
	if current_structure.reclaiming || current_structure.repairing:
		string = string.replace("%ENABLE_DISABLE_COLOR%", DISABLED_COLOR_STRING)
		string = string.replace("%STRUCTURE_RECLAIM_COLOR%", DISABLED_COLOR_STRING)
		string = string.replace("%STRUCTURE_REPAIR_COLOR%", DISABLED_COLOR_STRING)
	else:
		string = string.replace("%STRUCTURE_RECLAIM_COLOR%", ENABLED_COLOR_STRING)
		if current_structure.damaged:
			string = string.replace("%STRUCTURE_REPAIR_COLOR%", ENABLED_COLOR_STRING)
			string = string.replace("%ENABLE_DISABLE_COLOR%", DISABLED_COLOR_STRING)
		else:
			string = string.replace("%STRUCTURE_REPAIR_COLOR%", DISABLED_COLOR_STRING)
			string = string.replace("%ENABLE_DISABLE_COLOR%", ENABLED_COLOR_STRING)
		

	
	string = string.replace("%STRUCTURE_RECLAIM_RESOURCES%", current_structure.get_reclamation_resources_string())
	string = string.replace("%STRUCTURE_REPAIR_RESOURCES%", current_structure.get_repair_resources_string())
	return string


func _on_RichTextLabel_meta_clicked(meta):
	if debug:
		print("TileTooltip: meta clicked: " + meta)
	if meta == "repair":
		emit_signal("structure_tile_repaired", current_structure.structure_type_id, current_structure.tile_map_cell)
	if meta == "reclaim":
		emit_signal("confirm_structure_tile_reclaim", current_structure.structure_type_id, current_structure.tile_map_cell)
	if meta == "enable_disable":
		if current_structure.disabled:
			emit_signal("structure_tile_enabled", current_structure.structure_type_id, current_structure.tile_map_cell)
		else:
			emit_signal("structure_tile_disabled", current_structure.structure_type_id, current_structure.tile_map_cell)
	hide()
	_popup.hide()


func _on_RichTextLabel_mouse_exited():
	if debug:
		print("TileTooltip: tile_tooltip_mouse_exited emmited")
	hide()
	_popup.hide()
	emit_signal("tile_tooltip_auto_closed")

func _on_zoom_step_change_initiated(from_zoom_step: int, to_zoom_step: int, zoom_speed: float) -> void:
	if debug:
		print("TileTooltip: zoom changed to level/step %d" % to_zoom_step)
	_enable = to_zoom_step <= 1
	if visible:
		hide()
		_popup.hide()


func _on_structure_state_changed(tile_map_cell: Vector2) -> void:
	if !visible || current_structure == null:
		return
	var structure_mgr := StructureMgr.get_structure_mgr()
	current_structure = structure_mgr.get_structure(current_structure.tile_map_cell)
	if current_structure == null:
		hide()
		_popup.hide()
		return
	_rich_text_label.bbcode_text = _get_bb_code_string()
