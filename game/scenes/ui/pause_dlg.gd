extends Control



func _unhandled_input(event):
	if event.is_echo():
		return
	if event.is_action_pressed("pause"):
#		visible = !visible
#		get_tree().paused = visible
		if !visible:
			visible = true
			get_tree().paused = true
		else:
			visible = false
			get_tree().paused = false



func _on_ResumeBtn_pressed():
	hide()
	get_tree().paused = false


func _on_MainMenuBtn_pressed():
	transitionMgr.transitionTo(Constants.TITLE_SCENE_PATH, Constants.TRANSITION_SPEED)
