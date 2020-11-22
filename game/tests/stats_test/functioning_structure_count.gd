class_name FunctioningStructureCount
extends HBoxContainer

signal functional_structure_count_changed(structure_name, functional_count)

onready var _label := $StructureTypeName
onready var _spinbox := $SpinBox
onready var _num_structures_needed_label := $NumStructuresNeeded

var structure_type_name := "" setget _set_structure_type_name
var functional_count := 0 setget _set_functional_count
var num_structures_needed := 0.0 setget _set_num_structures_needed


func _set_structure_type_name(value: String) -> void:
	structure_type_name = value
	if _label != null:
		_label.text = value


func _set_functional_count(value: int) -> void:
	if value < 0:
		value = 0
	functional_count = value
	if _spinbox != null:
		_spinbox.value = value


func _set_num_structures_needed(value: float) -> void:
	if value < 0:
		value = 0
	num_structures_needed = value
	if _num_structures_needed_label != null:
		_num_structures_needed_label.text = _format_float(num_structures_needed)


func _format_float(f: float) -> String:
	return "%10.1f" % f


func _ready():
	SignalMgr.register_publisher(self, "functional_structure_count_changed")
	_label.text = structure_type_name
	_spinbox.value = functional_count
	_num_structures_needed_label.text = str(num_structures_needed)


func _on_SpinBox_value_changed(value):
	functional_count = int(value)
	emit_signal("functional_structure_count_changed", structure_type_name, functional_count)
	
