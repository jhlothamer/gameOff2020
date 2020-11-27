extends Node2D




func _ready():
	var index = randi() % get_child_count()
	var child_audio_stream: AudioStreamPlayer2D = get_child(index)
	child_audio_stream.connect("finished", self, "_on_audio_finished")
	child_audio_stream.play()


func _on_audio_finished():
	queue_free()
