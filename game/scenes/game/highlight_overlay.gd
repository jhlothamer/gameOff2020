extends TileMap




# Called when the node enters the scene tree for the first time.
func _ready():
#signal construction_button_mouse_entered(structure_type)
#signal construction_button_mouse_exited(structure_type)
	SignalMgr.register_subscriber(self, "construction_button_mouse_entered", "_on_construction_button_mouse_entered")
	SignalMgr.register_subscriber(self, "construction_button_mouse_exited", "_on_construction_button_mouse_exited")


func _on_construction_button_mouse_entered(structure_type_id):
	pass
	var structure_mgr := StructureMgr.get_structure_mgr()
	var structures = structure_mgr.get_structures_by_type_id(structure_type_id)
	for i in range(structures.size()):
		var structure: StructureMgr.StructureData = structures[i]
		set_cellv(structure.tile_map_cell, 0)

func _on_construction_button_mouse_exited(structure_type_id):
	clear()
