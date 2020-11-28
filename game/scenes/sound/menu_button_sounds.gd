extends Node

export var do_on_pressed_sound := true
export var do_mouse_over_sound := true

onready var _mouse_over_sound := $MouseOverSound
onready var _pressed_sound := $PressedSound

# [{binds:[], flags:2, method:_on_Button_pressed, signal:pressed, source:[Button:1282], target:[Button:1282]}]

var _pressed_signal_connection_list := []


func _ready():
	var parent = get_parent()
	
	if do_mouse_over_sound:
		parent.connect("mouse_entered", self, "_on_parent_mouse_entered")
	
	if do_on_pressed_sound:
		_pressed_signal_connection_list = parent.get_signal_connection_list("pressed")
		for connection in _pressed_signal_connection_list:
			parent.disconnect("pressed", connection.target, connection.method)
		parent.connect("pressed", self, "_on_parent_pressed")

func _on_parent_mouse_entered():
	_mouse_over_sound.play()
	
func _on_parent_pressed():
	_pressed_sound.play()


func _on_PressedSound_finished():
	for connection in _pressed_signal_connection_list:
		connection.target.call(connection.method)
