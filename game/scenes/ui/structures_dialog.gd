extends AcceptDialog


export var structure_row_color: Color
export var costs_row_color: Color


onready var _tree := $Tree
onready var _dialog_open_sound := $DialogOpenStreamPlayer
onready var _dialog_close_sound := $DialogCloseStreamPlayer

enum Columns{
	StructureName,
	Count,
	NumberActive,
	StatProvided,
	UnitsProvided,
	TotalUnitsProvided,
	PowerRequired,
	PopulationSupported
}

var _column_names := [
	"Structure",
	"#",
	"# Active",
	"Provides",
	"Units Per",
	"Total Units",
	"Power Req.",
	"Population Supported",
]


#func _ready():
#	show()

func show():
	get_tree().paused = true
	_refresh_contents()
	.show()
	popup_centered()
	_dialog_open_sound.play()


func _refresh_contents():
	_tree.clear()
	_tree.columns = _column_names.size()
	
	for column_id in EnumUtil.get_array(Columns):
		_tree.set_column_title(column_id, _column_names[column_id])
	
	_tree.set_column_titles_visible(true)
	#_tree.set_column_expand(Columns.StructureName, true)
	_tree.set_column_min_width(Columns.StructureName, 2)
	_tree.set_column_min_width(Columns.PopulationSupported, 2)
	_tree.set_column_min_width(Columns.StatProvided, 2)
	
	var root_item = _tree.create_item()
	
	var structure_mgr := StructureMgr.get_structure_mgr()
	var stats_mgr := StatsMgr.get_stat_mgr()
	
	for structure_type_id in EnumUtil.get_array(StructureMgr.StructureTileType):
#		if structure_type_id == StructureMgr.StructureTileType.UUC:
#			continue
		var structure_metadata := structure_mgr.get_structure_metadata(structure_type_id)
		var structure_item = _tree.create_item(root_item)
		
		#structure_item.set_expand_right(0, true)
		structure_item.set_custom_bg_color(0, structure_row_color)
		for i in range(1, _tree.columns):
			#structure_item.set_expand_right(i, false)
			structure_item.set_text_align(i, TreeItem.ALIGN_CENTER)
			structure_item.set_custom_bg_color(i, structure_row_color)

		structure_item.set_text(Columns.StructureName, structure_metadata.get_name())
		#number
		var structures = structure_mgr.get_structures_by_type_id(structure_type_id)
		structure_item.set_text(Columns.Count, str(structures.size()))
		#number active
		var functioning_structures = structure_mgr.get_functioning_structures_by_type_id(structure_type_id)
		structure_item.set_text(Columns.NumberActive, str(functioning_structures.size()))
		
		#provides
		var stat: StatsMgr.Stat = stats_mgr.get_stat_provided_by_structure_type_id(structure_type_id)
		if stat != null:
			structure_item.set_text(Columns.StatProvided, stat.stat_name)
			var units_per_structure = stat.get_units_per_structure()
			structure_item.set_text(Columns.UnitsProvided, str(units_per_structure))
			structure_item.set_text(Columns.TotalUnitsProvided, str(functioning_structures.size() * units_per_structure))
			if stat.has_population_schedule():
				var population_supported = stats_mgr.calc_structure_produced_stats(stat, functioning_structures)
				structure_item.set_text(Columns.PopulationSupported, str(population_supported))
			else:
				structure_item.set_text(Columns.PopulationSupported, "- -")
			
		else:
			structure_item.set_text(Columns.StatProvided, "- -")
			structure_item.set_text(Columns.UnitsProvided, "- -")
			structure_item.set_text(Columns.TotalUnitsProvided, "- -")
			structure_item.set_text(Columns.PopulationSupported, "- -")
		
		var power_required := structure_metadata.get_power_required()
		if power_required > 0.0:
			structure_item.set_text(Columns.PowerRequired, str(power_required))
		else:
			structure_item.set_text(Columns.PowerRequired, "- -")
		
		
		
		_set_bg_color(structure_item, structure_row_color)
		
		var costs_item = _tree.create_item(structure_item)
		_set_bg_color(costs_item, costs_row_color)
		costs_item.set_text(0, "Costs")
		costs_item.collapsed = true

		var construction_item = _tree.create_item(costs_item)
		_set_bg_color(construction_item, costs_row_color)
		construction_item.set_text(0, "Construction")
		construction_item.set_text(1, structure_metadata.get_construction_resources_string())

		var repair_item = _tree.create_item(costs_item)
		_set_bg_color(repair_item, costs_row_color)
		repair_item.set_text(0, "Repair")
		repair_item.set_text(1, structure_metadata.get_repair_resources_string())

		var reclaim_item = _tree.create_item(costs_item)
		_set_bg_color(reclaim_item, costs_row_color)
		reclaim_item.set_text(0, "Reclaim")
		reclaim_item.set_text(1, structure_metadata.get_reclamation_resources_string())
		

func _set_bg_color(item: TreeItem, bg_color: Color) -> void:
		for i in range(_tree.columns):
			item.set_custom_bg_color(i, bg_color)


func _on_StructuresDialog_popup_hide():
	get_tree().paused = false
	hide()
	_dialog_close_sound.play()


func _on_StructuresDialog_confirmed():
	get_tree().paused = false
	hide()
	_dialog_close_sound.play()


func _on_StructuresDialog_custom_action(action):
	get_tree().paused = false
	hide()
	_dialog_close_sound.play()
