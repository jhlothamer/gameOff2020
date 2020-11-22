extends HBoxContainer

var stat_name := "" setget _set_stat_name
var stat_value := 0.0 setget _set_value

onready var _name := $Name
onready var _value := $Value

func _set_stat_name(value: String) -> void:
	stat_name = value
	if _name != null:
		_name.text = stat_name

func _set_value(value: float) -> void:
	stat_value = value
	if _value != null:
		_value.text = _format_float(stat_value)

func _format_float(f: float) -> String:
	return "%10.2f" % f


func _ready():
	_name.text = stat_name
	_value.text = _format_float(stat_value)

