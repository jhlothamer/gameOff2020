extends Node2D

signal harvester_activated()

onready var fragments := [
	$FragmentBody,
	$FragmentBody2,
	$FragmentBody3
]

func _ready():
	Globals.set("SpawnMgr", self)
	SignalMgr.register_publisher(self, "harvester_activated")

func remove_fragment(fragment_body) -> void:
	fragments.erase(fragment_body)
	fragment_body.queue_free()


func _on_LaunchHarvesterBtn_pressed():
	emit_signal("harvester_activated")
