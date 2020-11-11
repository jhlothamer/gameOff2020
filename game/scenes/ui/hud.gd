extends CanvasLayer

signal focused_gained(control)

onready var dialogs: Control = $Dialogs
onready var resources_dialog: Control = $Dialogs/ResourcesDlg

var _last_control_focused: Control

func _ready():
	SignalMgr.register_publisher(self, "focused_gained")
	for child in dialogs.get_children():
		child.visible = false
	dialogs.visible = true


func _unhandled_input(event):
	if event is InputEventMouseButton:
		print("unhandled mouse button event")
		emit_signal("focused_gained", self)


func _on_ResourceDialogBtn_pressed():
	resources_dialog.show()
