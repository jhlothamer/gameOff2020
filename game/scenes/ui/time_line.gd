extends MarginContainer

signal YearHasElapsed()
signal TimeHasExpired()


export (int, 1, 60)  var game_time_length_minutes: int = 30
export (int, 1, 60) var seconds_per_year: int = 1

var _current_time_seconds: float
var _game_time_length_seconds: float
var _next_year_seconds: float

onready var _marker_templates_parent := $MarkersTemplates
onready var _generation_ship_path_follow := $Path2D/PathFollow2D


func _ready():
	SignalMgr.register_publisher(self, "YearHasElapsed")
	SignalMgr.register_publisher(self, "TimeHasExpired")
	_game_time_length_seconds = game_time_length_minutes * 60
	_next_year_seconds = float(seconds_per_year)
	for c in _marker_templates_parent.get_children():
		c.visible = false


func _process(delta):
	_current_time_seconds += delta
	if _current_time_seconds >= _next_year_seconds:
		_next_year_seconds += float(seconds_per_year)
		emit_signal("YearHasElapsed")
	var progress = _current_time_seconds / _game_time_length_seconds
	_generation_ship_path_follow.unit_offset = progress
	if progress >= 1.0:
		emit_signal("TimeHasExpired")
