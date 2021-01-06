extends AcceptDialog

const HELP_FILE_FILE_PATH_FORMAT := "res://assets/data/help/%s.txt"


onready var _tab_container = $MarginContainer/TabContainer
onready var _dialog_open_sound := $DialogOpenStreamPlayer
onready var _dialog_close_sound := $DialogCloseStreamPlayer
onready var _tab_switch_sound := $TabSwitchStreamPlayer


func _ready():
#	connect("about_to_show", self, "_on_HelpDialog2_about_to_show")
#	connect("popup_hide", self, "_on_HelpDialog2_popup_hide")
	call_deferred("_populate_help_tabs")


func _populate_help_tabs():
	var stat_mgr:StatsMgr = ServiceMgr.get_service(StatsMgr)
	var winning_population_amount = ""
	if stat_mgr != null:
		winning_population_amount = "%d" % stat_mgr.get_win_game_population_amount()

	for tab in _tab_container.get_children():
		var rich_text_label: RichTextLabel = tab.get_child(0)
		rich_text_label.bbcode_enabled = true
		var help_text:= _load_help_text(tab.name)
		help_text = help_text.replace("%WIN_POPULATION_AMOUNT%", winning_population_amount)
		rich_text_label.bbcode_text = help_text


func _load_help_text(name: String) -> String:
	var file_path = HELP_FILE_FILE_PATH_FORMAT % name.to_lower()
	return FileUtil.load_text(file_path)


func _on_HelpDialog2_about_to_show():
	get_tree().paused = true
	_dialog_open_sound.play()


func _on_HelpDialog2_popup_hide():
	_dialog_close_sound.play()
	get_tree().paused = false


func show():
	.show()
	popup_centered()


func _on_TabContainer_tab_changed(tab):
	_tab_switch_sound.play()
