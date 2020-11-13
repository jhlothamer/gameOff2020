extends AnimatedSprite

signal repair_complete()

var repair_time: float = 10.0

func _ready():
	yield(get_tree().create_timer(repair_time), "timeout")
	emit_signal("repair_complete")


