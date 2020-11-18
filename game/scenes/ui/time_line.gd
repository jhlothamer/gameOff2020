extends MarginContainer

signal YearHasElapsed()
signal TimeHasExpired()
signal AsteroidShowerEvent(event)

export (int, 1, 60)  var game_time_length_minutes: int = 30
export (int, 1, 60) var seconds_per_year: int = 1

var _current_time_seconds: float
var _game_time_length_seconds: float
var _next_year_seconds: float

# sprite object and event time
var timeline_markers = {}


#TODO: more types?
enum EventType {
	MeteorShower
}

#array of dicts( sorted by timeline order )
# event dict = enum:type, int:time(seconds), int:duration(seconds)
var event_schedule = []

onready var _marker_templates_parent := $MarkersTemplates
onready var _generation_ship_path_follow := $Path2D/PathFollow2D


class CustomSorter:
	static func sort_ascending(a, b):
		if a["time"] < b["time"]:
			return true
		return false

func _ready():
	SignalMgr.register_publisher(self, "YearHasElapsed")
	SignalMgr.register_publisher(self, "TimeHasExpired")
	SignalMgr.register_publisher(self, "AsteroidShowerEvent")
	_game_time_length_seconds = game_time_length_minutes * 60
	_next_year_seconds = float(seconds_per_year)
	for c in _marker_templates_parent.get_children():
		c.visible = false

func _add_event_dict(event: Dictionary)->bool:
	if event.has("type") and event["type"] in EventType.values() and \
	event.has("time") and event.has("duration"):
		event_schedule.push_back(event)
		_sort_timeline_events()
		_add_timeline_marker(event)
		return true
	else:
		print("malformed event dictionary passed to timeline")
		print(event)
	return false
	
func _add_timeline_marker(event):
	var new_sprite
	if event["type"] == 0:#asteroid/meteor
		new_sprite = $MarkersTemplates/meteor_shower_marker.duplicate()
	# calculate where to place it, scaled according to game time
	var total_seconds_in_game = game_time_length_minutes * 60
	var timeline_length_in_pixels = $HBoxContainer/TextureRect2.rect_size.x
	var scale = timeline_length_in_pixels / total_seconds_in_game
	var seconds_to_pixels = event["time"] * scale
	new_sprite.position.x = seconds_to_pixels + 20#offset
	new_sprite.show()
	timeline_markers[new_sprite] = event["time"]
	$Markers.add_child(new_sprite)

func _add_event(event_type:int, time:int, duration:int)->bool:
	var event_dict = {}
	if event_type in EventType.values():
		event_dict["type"] = event_type
	else:
		print("incorrect event type sent to timeline")
		print(event_type)
		return false
	event_dict["time"] = time
	event_dict["duration"] = duration
	event_schedule.push_back(event_dict)
	_sort_timeline_events()
	_add_timeline_marker(event_dict)
	return true
	
func _get_next_event() ->Dictionary:
	_sort_timeline_events()
	var next_event = null
	for x in event_schedule:
		if next_event == null:
			next_event = x
		else:
			if x["time"] < next_event["time"]:
				next_event = x
	# no need to compare to current time, the schedule should be pruned
	return next_event

func _sort_timeline_events():
	event_schedule.sort_custom(CustomSorter, "sort_ascending")
	
func _check_event_schedule():
	var closest_event = _get_next_event()
	var time_of_event = closest_event["time"]
	if _current_time_seconds > time_of_event:
		if closest_event["type"] == 0:
			emit_signal("AsteroidShowerEvent", closest_event.duplicate() )
			event_schedule.erase(closest_event)
			_clean_event_markers(closest_event)
			#start one event at a time, even if only a few frames apart.
			# simpler this way
			return
	var time_until_next_event = closest_event["time"] - int(_current_time_seconds)
	if time_until_next_event < 20:
		var type = ""
		if closest_event["type"] == 0:
			type = "Asteroid shower"
		print("time until next " + type + " is " + str(time_until_next_event) + " seconds away")
	

func _clean_event_markers(event_dict):
	var time_to_match = event_dict["time"]
	for x in timeline_markers.keys():
		if time_to_match == timeline_markers[x]:
			timeline_markers.erase(x)
			x.queue_free()
			

func _process(delta):
	_current_time_seconds += delta
	if _current_time_seconds >= _next_year_seconds:
		_next_year_seconds += float(seconds_per_year)
		_check_event_schedule()
		emit_signal("YearHasElapsed")
	var progress = _current_time_seconds / _game_time_length_seconds
	_generation_ship_path_follow.unit_offset = progress
	if progress >= 1.0:
		emit_signal("TimeHasExpired")
