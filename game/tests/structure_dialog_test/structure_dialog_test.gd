extends Control


onready var structure_dialog = $StructuresDialog


func _ready():
	pass # Replace with function body.


func _on_TestBtn_pressed():
	structure_dialog.show()
