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
onready var _timer := $Timer
onready var _tween := $Tween
onready var _instructions_container := $InstructionsMarginContainer
onready var _instructions := $InstructionsMarginContainer/VBoxContainer/Instructions
onready var _skip_btn := $SkipMarginContainer/SkipBtn
onready var _stat_mgr := $StatsMgr
onready var _intro1_vo := $Intro1AudioStreamPlayer
onready var _intro2_vo := $Intro2AudioStreamPlayer
onready var _intro3_vo := $Intro3AudioStreamPlayer

var _invisible_color := Color(1.0, 1.0, 1.0, 0.0)
var _visible_color := Color.white
var _skipped := false

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

func _ready():
	_intro_lines_1.visible = false
	_intro_lines_2.visible = false
	_intro_lines_3.visible = false
	_intro.visible = true
	_instructions_container.visible = false
	_instructions.bbcode_enabled = true
	var winning_population_amount = "%d" % _stat_mgr.get_win_game_population_amount()
	_instructions.bbcode_text = FileUtil.load_text(how_to_play_bbcode_file_path).replace("%WIN_POPULATION_AMOUNT%", winning_population_amount)
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
	
	if _skipped:
		return
	
	_on_SkipBtn_pressed()

func _intro_labels(parent: Control, intro_vo: AudioStreamPlayer, intro_begin: Array, intro_end: Array) -> void:
	var labels = parent.get_children()
	for label in labels:
		label.modulate = _invisible_color
	parent.visible = true
	
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
#		_timer.start(time_between_line_fade_ins_seconds)
#		yield(_timer,"timeout")
	
	if intro_vo.playing:
		yield(intro_vo,"finished")
	
	emit_signal("intro_lines_complete")


func _on_SkipBtn_pressed():
	_skipped = true
	_skip_btn.visible = false
	_intro.visible = false
	_instructions_container.modulate = _invisible_color
	_instructions_container.visible = true
	_tween.interpolate_property(_instructions_container, "modulate", _invisible_color, _visible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	#yield(_tween,"tween_all_completed")
