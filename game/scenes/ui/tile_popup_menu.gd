extends PopupMenu


signal structure_tile_reclaimed(structure_tile_type, cell_v)
signal structure_tile_repaired(structure_tile_type, cell_v)
signal structure_tile_disabled(structure_tile_type, cell_v)
signal structure_tile_enabled(structure_tile_type, cell_v)


var _current_structure: StructureMgr.StructureData

const NAME_ITEM_ID := 0
const REPAIR_ITEM_ID := 2
const RECLAIM_ITEM_ID := 3
const DISABLE_ITEM_ID := 4


func _ready():
	SignalMgr.register_publisher(self, "structure_tile_repaired")
	SignalMgr.register_publisher(self, "structure_tile_reclaimed")
	SignalMgr.register_publisher(self, "structure_tile_disabled")
	SignalMgr.register_publisher(self, "structure_tile_enabled")
	add_item("", 0) # will be filled with structure name
	set_item_disabled(0, true)
	add_separator()
	add_item("Repair", 2)
	add_item("Reclaim", 3)
	add_item("Disable", 4)

func show_for_structure(structure: StructureMgr.StructureData, position: Vector2):
	set_item_text(NAME_ITEM_ID, structure._get_name())
	set_item_disabled(REPAIR_ITEM_ID, !structure.damaged)
	set_item_disabled(DISABLE_ITEM_ID, structure.damaged)
	if structure.disabled:
		set_item_text(DISABLE_ITEM_ID, "Enable")
	else:
		set_item_text(DISABLE_ITEM_ID, "Disable")
	_current_structure = structure
	popup(Rect2(position, rect_size))
	#rect_position = position
	#show()


func _on_TilePopupMenu_id_pressed(id):
	if id == REPAIR_ITEM_ID:
		emit_signal("structure_tile_repaired", _current_structure.structure_type_id, _current_structure.tile_map_cell)
	elif id == RECLAIM_ITEM_ID:
		emit_signal("structure_tile_reclaimed", _current_structure.structure_type_id, _current_structure.tile_map_cell)
	elif id == DISABLE_ITEM_ID:
		if _current_structure.disabled:
			emit_signal("structure_tile_enabled", _current_structure.structure_type_id, _current_structure.tile_map_cell)
		else:
			emit_signal("structure_tile_disabled", _current_structure.structure_type_id, _current_structure.tile_map_cell)

func _unhandled_input(event):
	if !event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != BUTTON_RIGHT:
		return
	var structure_mgr := StructureMgr.get_structure_mgr()
	var structure: StructureMgr.StructureData = structure_mgr.get_structure_by_mouse_global_position()
	if structure == null:
		return
	show_for_structure(structure, get_global_mouse_position())
