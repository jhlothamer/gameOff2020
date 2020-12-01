extends Control

export var test_win_condition := false

onready var _animation_player := $AnimationPlayer
onready var _what_happened_label := $MarginContainer/Label
onready var _title_label := $MarginContainer3/Label
onready var _lose_voice_over := $VO_Game_End_Lose_FX
onready var _win_voice_over := $VO_Game_End_Win_FX

const win_text := "After centuries the impossible drive fell silent and the moon slipped into orbit around a new world.  Humanity had survived the void and would now build anew on alien shores.  Changed forever by the voyage in form and spirit they would never forget what happened to old Earth."
const lose_text := "After centuries the impossible drive fell silent and the moon slipped into orbit around a new world.  From the beginning accidents, new diseases and strife gripped the fledgling civilization till hope was lost and along with it humanities’ last chance."

const win_title := "A New World\r\nA New Chance"
const lose_title := "Insufficient\r\nPopulation"

func _ready():
	if _player_won():
		_what_happened_label.text = win_text
		_title_label.text = win_title
	else:
		_what_happened_label.text = lose_text
		_title_label.text = lose_title

func _player_won() -> bool:
	if test_win_condition:
		return true
	if Globals.get("won") == true:
		return true
	return false


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade in":
		_animation_player.play("ending")
	if anim_name == "ending":
		_animation_player.play("Show Ending Text")


func start_voice_over():
	if _player_won():
		_win_voice_over.play()
	else:
		_lose_voice_over.play()

