extends Control

onready var _animation_player := $AnimationPlayer


func _player_won() -> bool:
	if Globals.get("won") == true:
		return true
	return false


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade in":
		_animation_player.play("ending")
