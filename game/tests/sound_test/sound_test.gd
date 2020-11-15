extends Node2D

export var curve_in: CurveTexture


onready var tween: Tween = $Tween
onready var stream1: AudioStreamPlayer = $AudioStreamPlayer
onready var stream2: AudioStreamPlayer = $AudioStreamPlayer2


var _stream_length: float
var _current_position: float
var _current_stream: AudioStreamPlayer
var switch_time: float = 2.0
var _max_db:float = 0.0
var _min_db: float = -6*8
var _switch_time_counter: float = 0
var switching := false

func _ready():
	pass # Replace with function body.
	_stream_length = stream1.stream.get_length()
	_current_stream = stream1

func _process(delta):
	#_current_position = (_current_position + delta) % _stream_length
	_current_position += delta
	if _current_position > _stream_length:
		_current_position = _current_position - _stream_length
	
	if !switching:
		return
	
	_switch_time_counter += delta
	

func _on_TestBtn_pressed():
	if _current_stream == stream1:
		_do_stream_swap(stream1, stream2)
		_current_stream = stream2
	else:
		_do_stream_swap(stream2, stream1)
		_current_stream = stream1

func _do_stream_swap(from_stream: AudioStreamPlayer, to_stream: AudioStreamPlayer) -> void:
	to_stream.play(_current_position)
	tween.interpolate_property(from_stream, "volume_db", _max_db, _min_db, switch_time,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	tween.interpolate_property(to_stream, "volume_db", _min_db, _max_db, switch_time,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	#tween.interpolate_callback(self, switch_time, "_tween_callback", "foo", "bar")
	#tween.interpolate_method(self, "", _max_db, _min_db, switch_time,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	tween.start()
	yield(tween,"tween_all_completed")
	from_stream.stop()

func _tween_stream1(var x):
	stream1.volume_db = curve_in.curve.interpolate(x)

func _tween_stream2(var x):
	stream2.volume_db = curve_in.curve.interpolate(x)
