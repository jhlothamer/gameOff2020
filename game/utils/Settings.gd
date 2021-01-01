extends Node


const SETTINGS_FILE_PATH = "user://settings.json"


var _settings := {"tutorial_finished":false}


func _ready():
	_settings = FileUtil.load_json_data(SETTINGS_FILE_PATH, _settings)


func is_tutorial_finished() -> bool:
	var always_start = ProjectSettings.get("game/always_start_tutorial")
	if always_start:
		return false
	if _settings.has("tutorial_finished"):
		return _settings["tutorial_finished"]
	return false


func mark_tutorial_finished() -> void:
	_settings["tutorial_finished"] = true
	_save_settings()


func _save_settings() -> void:
	FileUtil.save_json_data(SETTINGS_FILE_PATH, _settings)
