extends ConfirmationDialog

signal structure_tile_reclaimed(structure_tile_type, cell_v)

const _confirmation_msg := "Are you sure you want to reclaim the %s?\r\nRegain: %s"
const _dialog_title := "Reclaim %s?"
var _structure_tile_type: int
var _cell_v := Vector2.ZERO

onready var _label = $Label2

func _ready():
	SignalMgr.register_publisher(self, "structure_tile_reclaimed")
	SignalMgr.register_subscriber(self, "confirm_structure_tile_reclaim", "_on_confirm_structure_tile_reclaim")


func _on_confirm_structure_tile_reclaim(structure_tile_type: int, cell_v: Vector2) -> void:
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	var structure_metadata := structure_mgr.get_structure_metadata(structure_tile_type)
	_label.text = _confirmation_msg % [structure_metadata.get_name(), structure_metadata.get_reclamation_resources_string()]
	window_title = _dialog_title % structure_metadata.get_name()	
	_structure_tile_type = structure_tile_type
	_cell_v = cell_v
	popup_centered()


func _on_ReclaimConfirmationDialog_confirmed():
	emit_signal("structure_tile_reclaimed", _structure_tile_type, _cell_v)
