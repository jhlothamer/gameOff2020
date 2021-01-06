extends CenterContainer

signal continue_pressed()

var id := 0

func _on_Button_pressed():
	emit_signal("continue_pressed")

func dismiss():
	queue_free()
