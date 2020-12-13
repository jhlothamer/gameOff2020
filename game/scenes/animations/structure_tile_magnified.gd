extends Node2D

var structure_type_id: int setget _set_structure_type_id
var expanded_scale := 2.0
var expand_time := .2

onready var _tween := $Tween
onready var _animated_sprite := $AnimatedSprite

func _ready():
	_set_structure_type_id(structure_type_id)
	call_deferred("_animate_expand")

func _set_structure_type_id(value):
	structure_type_id = value
	if _animated_sprite == null:
		return
	_animated_sprite.frame = structure_type_id


func _animate_expand():
	_tween.interpolate_property(_animated_sprite, "scale", Vector2.ONE, Vector2.ONE*expanded_scale, expand_time,Tween.TRANS_BOUNCE,Tween.EASE_IN_OUT)
	_tween.start()

func delete():
	_tween.stop_all()
	_tween.interpolate_property(_animated_sprite, "scale", _animated_sprite.scale, Vector2.ONE*expanded_scale, expand_time,Tween.TRANS_BOUNCE,Tween.EASE_IN_OUT)
	_tween.start()
	#yield(_tween, "tween_all_completed")
	yield(get_tree().create_timer(expand_time),"timeout")
	queue_free()
