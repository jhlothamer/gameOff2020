class_name HudAlertsMgr
extends Control

onready var _hud_alert_label_parent := $MarginContainer/VBoxContainer

var _hud_alert_label_class := preload("res://scenes/ui/hud_alert_label.tscn")

onready var vo_alert_insufficient_resources := $VO_Alerts_Insufficient_Resources
onready var vo_alert_structure_damaged := $VO_Alerts_Structure_Damaged

onready var _message_to_vo := {
	"Incoming Asteroids": $VO_Alerts_Incoming_Asteroids,
	"Harvester returning to barn": $VO_Alerts_Harvester_Returning,
	"Harvester ready": $VO_Alerts_Harvester_Ready,
	"Population is crashing!": $VO_Alerts_Population_Crash_Imminent,
}

var _audio_stream_queue := []

func _ready():
	Globals.set("HudAlertsMgr", self)
	for c in get_children():
		if c is AudioStreamPlayer:
			c.connect("finished", self, "_on_VO_Alerts_Harvester_Ready_finished")


static func get_hud_alerts_mgr() -> HudAlertsMgr:
	return Globals.get("HudAlertsMgr")


static func add_hud_alert(msg: String) -> void:
	var hud_alert_mgr := get_hud_alerts_mgr()
	if hud_alert_mgr == null:
		return
	hud_alert_mgr._add_hud_alert(msg)


func _add_hud_alert(msg: String) -> void:
	var hud_alert_label = _hud_alert_label_class.instance()
	hud_alert_label.text = msg
	_hud_alert_label_parent.add_child(hud_alert_label)

	if msg.ends_with("Damaged"):
		_push_audio_stream(vo_alert_structure_damaged)
	elif msg.begins_with("Not enough resources to construct"):
		_push_audio_stream(vo_alert_insufficient_resources)
	elif _message_to_vo.has(msg):
		_push_audio_stream(_message_to_vo[msg])

func _push_audio_stream(audio_stream: AudioStreamPlayer) -> void:
	if _audio_stream_queue.size() == 0:
		_audio_stream_queue.push_back(audio_stream)
		audio_stream.play()
	elif _audio_stream_queue[_audio_stream_queue.size() - 1] != audio_stream:
		_audio_stream_queue.push_back(audio_stream)


func _on_VO_Alerts_Harvester_Ready_finished():
	_audio_stream_queue.pop_front()
	if _audio_stream_queue.size() > 0:
		_audio_stream_queue[0].play()

