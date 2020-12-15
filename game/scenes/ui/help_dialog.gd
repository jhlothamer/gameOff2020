extends AcceptDialog

onready var _rich_text_label := $MarginContainer/RichTextLabel
onready var _dialog_open_sound := $DialogOpenStreamPlayer
onready var _dialog_close_sound := $DialogCloseStreamPlayer


func _ready():
	_rich_text_label.bbcode_enabled = true
	var stat_mgr:StatsMgr = ServiceMgr.get_service(StatsMgr)
	if stat_mgr == null:
		return
	var winning_population_amount = "%d" % stat_mgr.get_win_game_population_amount()
	_rich_text_label.bbcode_text = FileUtil.load_text(HowToPlay.how_to_play_bbcode_file_path).replace("%WIN_POPULATION_AMOUNT%", winning_population_amount)


func show():
	.show()
	popup_centered()


func _on_HelpDialog_about_to_show():
	get_tree().paused = true
	_dialog_open_sound.play()


func _on_HelpDialog_popup_hide():
	_dialog_close_sound.play()
	get_tree().paused = false
