extends Node2D

signal resource_amount_added(resource_name, amount)

var fragment_harvest_amount := 500.0 setget _set_fragment_harvest_amount

const _label_string_format = "+ %d Ore"

onready var _label = $Label

func _ready():
	SignalMgr.register_publisher(self, "resource_amount_added")

func _set_fragment_harvest_amount(value):
	fragment_harvest_amount = value
	if _label != null:
		_label.text = _label_string_format % fragment_harvest_amount


func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("resource_amount_added", "ore", fragment_harvest_amount)
	queue_free()
