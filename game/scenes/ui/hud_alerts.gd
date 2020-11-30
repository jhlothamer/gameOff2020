class_name HudAlertsMgr
extends Control

onready var _hud_alert_label_parent := $MarginContainer/VBoxContainer


var _hud_alert_label_class := preload("res://scenes/ui/hud_alert_label.tscn")


func _ready():
	Globals.set("HudAlertsMgr", self)

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
