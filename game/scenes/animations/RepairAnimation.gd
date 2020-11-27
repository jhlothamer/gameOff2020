extends AnimatedSprite

signal repair_complete()

#var repair_time: float = 3.0

func _ready():
	#yield(get_tree().create_timer(repair_time), "timeout")
	yield(get_tree().create_timer(.7), "timeout")
	frame = 1
	yield(get_tree().create_timer(1.35-.7), "timeout")
	frame = 2
	yield(get_tree().create_timer(3.0-1.35-.7), "timeout")
	emit_signal("repair_complete")


