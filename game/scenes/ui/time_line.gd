extends "res://scenes/ui/time_line_interface.gd"

signal stat_cycle_time_has_elapsed()
signal time_has_expired()
signal AsteroidShowerEvent(event)

export (int, 1, 60)  var game_time_length_minutes: int = 30
export (int, 0, 100000) var starting_game_time_seconds: int = 0
export (int, 1, 60) var seconds_per_stat_cycle_time: int = 1
export var active := false

var _current_time_seconds: float
var _game_time_length_seconds: float
var _next_year_seconds: float


export var shower_duration_min: int = 15
export var shower_duration_max: int = 30
export var range_of_time_between_showers: int = 50

export var showers_per_game_min: int = 5
export var showers_per_game_max: int = 10

export (int, 0, 120) var showers_time_margine_begin_end := 60

var event_check_frequency = 30

# sprite object and event time
var timeline_markers = {}


enum EventType {
	MeteorShower
}

#array of dicts( sorted by timeline order )
# event dict = enum:type, int:time(seconds), int:duration(seconds)
var event_schedule = []

onready var _marker_templates_parent := $MarkersTemplates
onready var _generation_ship_path_follow := $Path2D/PathFollow2D
onready var _line2d := $Path2D/PathFollow2D/Sprite/Line2D
onready var _markers_parent := $Markers
onready var _meteor_shower_marker := $MarkersTemplates/meteor_shower_marker
onready var _timeline_texture_rect := $HBoxContainer/TimeLineTextureRect
onready var _animation_player := $AnimationPlayer

var _line2d_length := 1.0

class CustomSorter:
	static func sort_ascending(a, b):
		if a["time"] < b["time"]:
			return true
		return false


func _enter_tree():
	ServiceMgr.register_service(TimeLine, self)


func _ready():
	SignalMgr.register_publisher(self, "stat_cycle_time_has_elapsed")
	SignalMgr.register_publisher(self, "time_has_expired")
	SignalMgr.register_publisher(self, "AsteroidShowerEvent")
	_line2d_length = abs(_line2d.points[1].x - _line2d.points[0].x)
	_game_time_length_seconds = game_time_length_minutes * 60
	if starting_game_time_seconds > 0:
		_current_time_seconds = min(float(starting_game_time_seconds), _game_time_length_seconds)
	_next_year_seconds = float(seconds_per_stat_cycle_time)
	for c in _marker_templates_parent.get_children():
		c.visible = false
	_initialize_timeline()

func _add_event_dict(event: Dictionary)->bool:
	if event.has("type") and event["type"] in EventType.values() and \
	event.has("time") and event.has("duration"):
		event_schedule.push_back(event)
		_add_timeline_marker(event)
		return true
	else:
		print("malformed event dictionary passed to timeline")
		print(event)
	return false
	
func _add_timeline_marker(event):
	var new_sprite
	if event["type"] == 0:#asteroid/meteor
		new_sprite = _meteor_shower_marker.duplicate()
	# calculate where to place it, scaled according to game time
	var total_seconds_in_game = game_time_length_minutes * 60
	var timeline_length_in_pixels = _timeline_texture_rect.rect_size.x
	var scale = timeline_length_in_pixels / total_seconds_in_game
	var seconds_to_pixels = event["time"] * scale
	new_sprite.position.x = seconds_to_pixels + 20#offset
	new_sprite.show()
	timeline_markers[new_sprite] = event["time"]
	_markers_parent.add_child(new_sprite)
	
func _get_next_event() ->Dictionary:
	var ret = {}
	if event_schedule.empty():
		return ret
	else:
		return event_schedule[0]

func _sort_timeline_events():
	event_schedule.sort_custom(CustomSorter, "sort_ascending")

func _initialize_timeline():
	var total_game_time = game_time_length_minutes * 60
	var adjusted_time_range = total_game_time - showers_time_margine_begin_end
	var total_shower_events = randi() % (showers_per_game_max - showers_per_game_min) + showers_per_game_min
	for x in range( 0, total_shower_events ):
		var seconds_event = showers_time_margine_begin_end + ( x * adjusted_time_range / total_shower_events )
		seconds_event += rand_range(-range_of_time_between_showers,range_of_time_between_showers)
		if seconds_event > total_game_time:
			seconds_event = total_game_time - (showers_time_margine_begin_end + rand_range(-20,20))
		var event_dict = {}
		event_dict["type"] = 0
		event_dict["time"] = seconds_event
		event_dict["duration"] = randi() % (shower_duration_max - shower_duration_min) + shower_duration_min
		if _add_event_dict(event_dict):
			pass
		else:
			print("adding event failed type = " + str(event_dict["type"] + " at " + str(event_dict["time"] + " seconds ")))
	_sort_timeline_events()

func _check_event_schedule():
	var closest_event = _get_next_event()
	if closest_event.empty():
		return
	var time_of_event = closest_event["time"]
	if _current_time_seconds > time_of_event:
		if closest_event["type"] == 0:
			emit_signal("AsteroidShowerEvent", closest_event.duplicate() )
			HudAlertsMgr.add_hud_alert("Incoming Asteroids")
			HudAlertsMgr.add_hud_alert("Prepare to deploy harvester")
			event_schedule.erase(closest_event)
			_clean_event_markers(closest_event)
			#start one event at a time, even if only a few frames apart.
			# simpler this way
			return
	var time_until_next_event = closest_event["time"] - int(_current_time_seconds)
	if time_until_next_event < 20:
		if !closest_event.has("alerted"):
			closest_event["alerted"] = true
		# var type = ""
		# if closest_event["type"] == 0:
		# 	type = "Asteroid shower"
		#print("time until next " + type + " is " + str(time_until_next_event) + " seconds away")
	

func _clean_event_markers(event_dict):
	var time_to_match = event_dict["time"]
	for x in timeline_markers.keys():
		if time_to_match == timeline_markers[x]:
			timeline_markers.erase(x)
			x.queue_free()
			

func _process(delta):
	if !active:
		return
	_current_time_seconds += delta
	if event_check_frequency <= 0:
		_check_event_schedule()
		event_check_frequency = 30
	else:
		event_check_frequency -= 1
	if _current_time_seconds >= _next_year_seconds:
		_next_year_seconds += float(seconds_per_stat_cycle_time)
		emit_signal("stat_cycle_time_has_elapsed")
	var progress = _current_time_seconds / _game_time_length_seconds
	_generation_ship_path_follow.unit_offset = progress
	if progress >= 1.0:
		emit_signal("time_has_expired")


func activate() -> void:
	active = true


func deactivate() -> void:
	active = false

func _set_drive_on(value):
	drive_on = value
	if _line2d == null:
		return
	_line2d.visible = drive_on


func _set_exhaust_length_percent(value):
	exhaust_length_percent = value
	if _line2d == null:
		return
	var new_length = value * _line2d_length
	_line2d.points[1].x = _line2d.points[0].x - new_length


func show_highlight():
	_animation_player.play("show highlight", -1, .3)


func hide_highlight():
	_animation_player.play("hide highlight")


