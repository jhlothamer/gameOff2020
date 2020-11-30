class_name DifficultySettings
extends Control

enum DifficultyLevels {
	Easy,
	Medium,
	Hard
}

onready var _difficulty_level_controls := {
	DifficultyLevels.Easy: [$GridContainer/EasySelectionTextureRect, $GridContainer/EasyLabel],
	DifficultyLevels.Medium: [$GridContainer/MediumSelectionTextureRect, $GridContainer/MediumLabel],
	DifficultyLevels.Hard: [$GridContainer/HardSelectionTextureRect, $GridContainer/HardLabel],
}

onready var _medium_difficulty_btn = $GridContainer/MediumDifficultyBtn

onready var _stat_mgr := $StatsMgr

var _invisible_color := Color(1, 1, 1, 0)
var _selected_color_label := Color("#ff0076")
var _hover_color_label := Color(0, 1, 1, 1)

const _difficulty_label_format = "Target population is %d with game length of 20 minutes."

func _ready():
	_medium_difficulty_btn.pressed = true
	#yield(_stat_mgr, "stats_updated")
	var win_amounts:Dictionary = _stat_mgr.get_win_game_population_amounts()
	_update_difficulty_label_text(DifficultyLevels.Easy, win_amounts[DifficultyLevels.Easy])
	_update_difficulty_label_text(DifficultyLevels.Medium, win_amounts[DifficultyLevels.Medium])
	_update_difficulty_label_text(DifficultyLevels.Hard, win_amounts[DifficultyLevels.Hard])

func _update_difficulty_label_text(level: int, win_population: int) -> void:
	pass
	var controls = _difficulty_level_controls[level]
	controls[1].text = _difficulty_label_format % win_population


func _update_difficulty_level_controls(level: int, selected):
	var controls = _difficulty_level_controls[level]
	if selected:
		controls[0].modulate = Color.white
		controls[1].set("custom_colors/font_color", _selected_color_label)
		set_difficulty_setting(level)
	else:
		controls[0].modulate = _invisible_color
		controls[1].set("custom_colors/font_color", Color.white)

func _on_EasyDifficultyBtn_toggled(button_pressed):
	_update_difficulty_level_controls(DifficultyLevels.Easy, button_pressed)


func _on_MediumDifficultyBtn_toggled(button_pressed):
	_update_difficulty_level_controls(DifficultyLevels.Medium, button_pressed)


func _on_HardDifficultyBtn_toggled(button_pressed):
	_update_difficulty_level_controls(DifficultyLevels.Hard, button_pressed)


func set_difficulty_setting(difficulty_level: int) -> void:
	Globals.set("difficulty", difficulty_level)

static func get_difficulty_setting() -> int:
	var raw_setting_value = Globals.get("difficulty")
	if raw_setting_value == null:
		return DifficultyLevels.Medium
	return raw_setting_value
