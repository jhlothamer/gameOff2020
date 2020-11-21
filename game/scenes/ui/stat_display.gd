extends MarginContainer

export var stat_name := "Population"
export var stat_delta_increase_color := Color.green
export var stat_delta_decrease_color := Color.red
export var stat_no_delta_color := Color.white

onready var _stat_name_label := $VBoxContainer/StatName
onready var _stat_value_label := $VBoxContainer/StatValueAndDelta/StatValue
onready var _stat_value_delta_label := $VBoxContainer/StatValueAndDelta/StatValueDelta
onready var _stat_value_delta_indicator := $VBoxContainer/StatValueAndDelta/DeltaIndicatorCtrl/DeltaIndicatorSprite


const no_delta_indicator_index := 0
const increase_delta_indicator_index := 1
const decrease_delta_indicator_index := 2


func _ready():
	SignalMgr.register_subscriber(self, "stats_updated", "_on_stats_updated")
	_stat_name_label.text = stat_name


func _on_stats_updated():
	var stat_mgr = StatsMgr.get_stat_mgr()
	var stat:StatsMgr.Stat = stat_mgr.get_stat_by_name(stat_name)
	var value = stat.get_value()
	var delta = stat.get_delta()
	_stat_value_label.text = "%d" % value
	_stat_value_delta_label.text = "%d" % delta
	if is_zero_approx(delta):
		_stat_value_delta_indicator.frame = no_delta_indicator_index
		_stat_value_delta_label.modulate = stat_no_delta_color
	elif delta > 0:
		_stat_value_delta_indicator.frame = increase_delta_indicator_index
		_stat_value_delta_label.modulate = stat_delta_increase_color
	else:
		_stat_value_delta_indicator.frame = decrease_delta_indicator_index
		_stat_value_delta_label.modulate = stat_delta_decrease_color
	
