class_name HowToPlay
extends TextureRect

signal intro_lines_complete()

const how_to_play_bbcode_file_path := "res://assets/data/how_to_play_bbcode.txt"

export (float, .1, 100.0) var line_fade_in_time_seconds := 1.0
export (float, .1, 100.0) var time_between_line_fade_ins_seconds := 1.0

onready var _intro := $Introduction
onready var _intro_lines_1 := $Introduction/IntroLines1
onready var _intro_lines_2 := $Introduction/IntroLines2
onready var _intro_lines_3 := $Introduction/IntroLines3
onready var _intro_lines_4 := $Introduction/IntroLines4
onready var _timer := $Timer
onready var _tween := $Tween
onready var _intro1_vo := $Intro1AudioStreamPlayer
onready var _intro2_vo := $Intro2AudioStreamPlayer
onready var _intro3_vo := $Intro3AudioStreamPlayer
onready var _start_with_tutorial_check_box := $SkipMarginContainer/CenterContainer/StartWithTutorialCheckBox

var _invisible_color := Color(1.0, 1.0, 1.0, 0.0)
var _visible_color := Color.white

var _intro_lines_begin1 := [
	0.00,
	2.034, 
	4.018, 
	6.60,
	9.512, 
	12.583,
	14.327]
var _intro_lines_end1 := [
	1.555,
	3.619,
	6.521,
	8.993,
	11.875,
	14.337,
	16.521]
var _intro_lines_begin2 := [
	0.00,
	2.639,
	5.610,
	9.583,
	11.534]
var _intro_lines_end2 := [
	2.397,
	5.354,
	8.725,
	11.534,
	13.469]
var _intro_lines_begin3 := [
	0.000,
	2.279,
	3.997,
	5.59, 
	8.76, 
	9.935,
	11.288]
var _intro_lines_end3 := [
	2.074,
	3.757,
	5.599,
	8.128,
	9.935,
	11.199,
	14.858]
var _intro_lines_begin4 := [
	0.000
]
var _intro_lines_end4 := [
	2.000
]

func _ready():
	_intro_lines_1.visible = false
	_intro_lines_2.visible = false
	_intro_lines_3.visible = false
	_intro.visible = true
	
	if Settings.is_tutorial_finished():
		_start_with_tutorial_check_box.visible = true
	else:
		_start_with_tutorial_check_box.visible = false
	
	call_deferred("_start_intro")

func _start_intro():
	_timer.start(time_between_line_fade_ins_seconds)
	yield(_timer,"timeout")

	_intro_labels(_intro_lines_1, _intro1_vo, _intro_lines_begin1, _intro_lines_end1)
	yield(self, "intro_lines_complete")
	_tween.interpolate_property(_intro_lines_1, "modulate", _intro_lines_1.modulate, _invisible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	yield(_tween,"tween_all_completed")

	_timer.start(time_between_line_fade_ins_seconds)
	yield(_timer,"timeout")

	_intro_labels(_intro_lines_2, _intro2_vo, _intro_lines_begin2, _intro_lines_end2)
	yield(self, "intro_lines_complete")
	_tween.interpolate_property(_intro_lines_2, "modulate", _intro_lines_2.modulate, _invisible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	yield(_tween,"tween_all_completed")

	_timer.start(time_between_line_fade_ins_seconds)
	yield(_timer,"timeout")

	_intro_labels(_intro_lines_3, _intro3_vo, _intro_lines_begin3, _intro_lines_end3)
	yield(self, "intro_lines_complete")
	_tween.interpolate_property(_intro_lines_3, "modulate", _intro_lines_3.modulate, _invisible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	yield(_tween,"tween_all_completed")

	_intro_labels(_intro_lines_4, null, _intro_lines_begin4, _intro_lines_end4)
	
	

func _intro_labels(parent: Control, intro_vo: AudioStreamPlayer, intro_begin: Array, intro_end: Array) -> void:
	var labels = parent.get_children()
	for label in labels:
		label.modulate = _invisible_color
	parent.visible = true
	
	if intro_vo != null:
		intro_vo.play()
	
	#for label in labels:
	for i in range(labels.size()):
		if i > 0:
			var begin_pause_time = intro_begin[i] - intro_end[i-1]
			if begin_pause_time > 0:
				_timer.start(begin_pause_time)
				yield(_timer,"timeout")
		
		var current_fade_in_time = intro_end[i] - intro_begin[i]
		var label = labels[i]
		_tween.interpolate_property(label, "modulate", label.modulate, _visible_color, current_fade_in_time,Tween.TRANS_LINEAR,Tween.EASE_IN)
		_tween.start()
		yield(_tween, "tween_all_completed")

	
	if intro_vo != null && intro_vo.playing:
		yield(intro_vo,"finished")
	
	emit_signal("intro_lines_complete")


func _on_StartWithTutorialCheckBox_toggled(button_pressed):
	if button_pressed:
		Settings.mark_tutorial_unfinished()
	else:
		Settings.mark_tutorial_finished()
