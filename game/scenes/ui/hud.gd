extends CanvasLayer

signal focused_gained(control)
signal reclaim_structure_initiated()
signal random_damage_test_clicked()

onready var dialogs: Control = $Dialogs
onready var resources_dialog: Control = $Dialogs/ResourcesDlg
onready var structures_dialog := $Dialogs/StructuresDialog

var _last_control_focused: Control

func _ready():
	SignalMgr.register_publisher(self, "focused_gained")
	SignalMgr.register_publisher(self, "reclaim_structure_initiated")
	SignalMgr.register_publisher(self, "random_damage_test_clicked")
	for child in dialogs.get_children():
		child.visible = false
	dialogs.visible = true


func _unhandled_input(event):
	if event is InputEventMouseButton:
		#print("unhandled mouse button event")
		emit_signal("focused_gained", self)


func _on_ResourceDialogBtn_pressed():
	if !resources_dialog.visible:
		resources_dialog.show()
	else:
		resources_dialog.hide()


func _on_DeconstructBtn_pressed():
	emit_signal("reclaim_structure_initiated")


func _on_RndDmgTestBtn_pressed():
	emit_signal("random_damage_test_clicked")


func _on_StructureInfoBtn_pressed():
	structures_dialog.show()
