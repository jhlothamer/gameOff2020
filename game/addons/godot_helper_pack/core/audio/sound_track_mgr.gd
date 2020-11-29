class_name SoundTrackMgr
extends Node

func _ready():
	var _results = get_tree().connect("node_added", self, "_on_node_added")
	

func _on_node_added(node : Node):
	if node.get_parent() != get_tree().root:
		return
	var path = str(node.get_path())
	var scene_name = path.replace("/root/", "")
	_play_scene(scene_name)

func _play_scene(scene_name: String) -> void:
	print("SoundTrackMgr: checking scene " + scene_name)
	for child in get_children():
		if !child is SceneSoundTrack:
			continue
		var sceneSoundTrack:SceneSoundTrack = child
		if sceneSoundTrack.check_scene_and_play(scene_name):
			return
