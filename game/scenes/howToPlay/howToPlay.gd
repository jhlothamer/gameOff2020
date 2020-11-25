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

var _invisible_color := Color(1.0, 1.0, 1.0, 0.0)
var _visible_color := Color.white
var _skipped := false

func _ready():
	_intro_lines_1.visible = false
	_intro_lines_2.visible = false
	_intro_lines_3.visible = false
	_intro.visible = true
	_instructions_container.visible = false
	_instructions.bbcode_enabled = true
	_instructions.bbcode_text = FileUtil.load_text(how_to_play_bbcode_file_path)
	call_deferred("_start_intro")

func _start_intro():
	_timer.start(time_between_line_fade_ins_seconds)
	yield(_timer,"timeout")

	_intro_labels(_intro_lines_1)
	yield(self, "intro_lines_complete")
	_tween.interpolate_property(_intro_lines_1, "modulate", _intro_lines_1.modulate, _invisible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	yield(_tween,"tween_all_completed")

	_timer.start(time_between_line_fade_ins_seconds)
	yield(_timer,"timeout")

	_intro_labels(_intro_lines_2)
	yield(self, "intro_lines_complete")
	_tween.interpolate_property(_intro_lines_2, "modulate", _intro_lines_2.modulate, _invisible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	yield(_tween,"tween_all_completed")

	_timer.start(time_between_line_fade_ins_seconds)
	yield(_timer,"timeout")

	_intro_labels(_intro_lines_3)
	yield(self, "intro_lines_complete")
	_tween.interpolate_property(_intro_lines_3, "modulate", _intro_lines_3.modulate, _invisible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	yield(_tween,"tween_all_completed")

func _intro_labels(parent: Control):
	var labels = parent.get_children()
	for label in labels:
		label.modulate = _invisible_color
	parent.visible = true
	
	for label in labels:
		_tween.interpolate_property(label, "modulate", label.modulate, _visible_color, line_fade_in_time_seconds,Tween.TRANS_LINEAR,Tween.EASE_IN)
		_tween.start()
		yield(_tween, "tween_all_completed")
		_timer.start(time_between_line_fade_ins_seconds)
		yield(_timer,"timeout")
	
	emit_signal("intro_lines_complete")


func _on_SkipBtn_pressed():
	_skipped = true
	_skip_btn.visible = false
	_intro.visible = false
	_instructions_container.visible = true
	_tween.interpolate_property(_instructions_container, "modulate", _invisible_color, _visible_color, time_between_line_fade_ins_seconds,Tween.TRANS_LINEAR, Tween.EASE_OUT)
	_tween.start()
	#yield(_tween,"tween_all_completed")
