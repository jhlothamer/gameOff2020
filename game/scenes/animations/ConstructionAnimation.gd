extends AnimatedSprite

onready var construction_audio_stream := $ConstructionAudioStream
onready var reclamation_audio_stream := $ReclamationAudioStream


func play_construction_animation():
	construction_audio_stream.play()
	play("default")


func play_reclamation_animation():
	reclamation_audio_stream.play()
	play("default", true)
