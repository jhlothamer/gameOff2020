extends Node


export var volume_db: float setget _set_volume_db
export var autoplay := false

export var min_seconds_between_play: float = 1.0
export var max_seconds_between_play: float = 5.0

export var debug := false

var playing := false setget _set_playing

onready var _timer := $Timer

var _audio_stream_children := []
var _current_playing_audio_child

func _set_volume_db(value: float) -> void:
	volume_db = value
	_update_children_volume_db(value)

func _set_playing(value: bool) -> void:
	if playing == value:
		return
	playing = value
	if Engine.editor_hint:
		return


func _ready():
	for c in get_children():
		if c is AudioStreamPlayer or c is AudioStreamPlayer2D:
			_audio_stream_children.append(c)
			c.connect("finished", self, "_on_audio_stream_player_finished")
	if autoplay:
		_play_rand_audio_child()


func _update_children_volume_db(value: float) -> void:
	for c in _audio_stream_children:
		c.volume_db = value


func _on_audio_stream_player_finished():
	if debug:
		print("child audio stream finished")
	_current_playing_audio_child = null
	if !playing:
		if debug:
			print("no longer playing as child audio stream finished")
		return
	_start_timer()


func _start_timer():
	_timer.start(rand_range(min_seconds_between_play, max_seconds_between_play))
	if debug:
		print("starting rand audio timer with wit time " + str(_timer.wait_time))



func _on_Timer_timeout():
	if !playing:
		return
	_play_rand_audio_child()


func _play_rand_audio_child():
	var child_count = _audio_stream_children.size()
	if child_count == 0:
		return
	var child_index = randi() % child_count
	var audio_child = _audio_stream_children[child_index]
	audio_child.play()
	_current_playing_audio_child = audio_child
	if debug:
		print("playing rand audio child " + audio_child.name)


func play():
	if playing:
		return
	playing = true
	_play_rand_audio_child()


func stop():
	if !playing:
		return
	playing = false
	if _current_playing_audio_child != null:
		_current_playing_audio_child.stop()
		_current_playing_audio_child = null
