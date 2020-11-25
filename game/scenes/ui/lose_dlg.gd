extends Control




func _ready():
	SignalMgr.register_subscriber(self, "population_crashed_game_over", "_on_population_crashed_game_over")

func _on_population_crashed_game_over():
	get_tree().paused = true
	visible = true

func _on_TryAgainBtn_pressed():
	transitionMgr.transitionTo(Constants.GAME_SCENE_PATH, Constants.TRANSITION_SPEED)


func _on_MainMenuBtn_pressed():
	transitionMgr.transitionTo(Constants.TITLE_SCENE_PATH, Constants.TRANSITION_SPEED)
