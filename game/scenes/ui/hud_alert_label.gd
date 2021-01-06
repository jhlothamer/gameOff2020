extends Label

var id: int = 0
var sticky: bool = false

onready var _animation_player := $AnimationPlayer

func _ready():
	if !sticky:
		_animation_player.play("AnimateLabel")
	else:
		_animation_player.play("fade in")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade in":
		return
	queue_free()

func dismiss():
	_animation_player.play("fade out")

