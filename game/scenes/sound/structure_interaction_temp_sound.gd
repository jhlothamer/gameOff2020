class_name StructureInteractionTempSound
extends Node2D

onready var player_deactive_sound := $PlayerDeactiveSound
onready var player_reactive_sound := $PlayerReactiveSound
onready var placement_sound := $PlacementSound
onready var failure_deactive_sound := $FailureDeactiveSound


func play_player_deactivate_sound():
	player_deactive_sound.play()


func play_player_reactive_sound():
	player_reactive_sound.play()


func play_placement_sound():
	placement_sound.play()

func play_failure_deactive_sound():
	failure_deactive_sound.play()


func _on_PlayerDeactiveSound_finished():
	queue_free()


func _on_PlayerReactiveSound_finished():
	queue_free()


func _on_PlacementSound_finished():
	queue_free()


func _on_FailureDeactiveSound_finished():
	queue_free()

