extends TextureRect


onready var _credits_labels := [
	$MarginContainer/VBoxContainer/HBoxContainer/AaronBowersCreditsLabel,
	$MarginContainer/VBoxContainer/HBoxContainer/LeanneBowersCreditsLabel,
	$MarginContainer/VBoxContainer/HBoxContainer2/BobrobbowCreditsLabel,
	$MarginContainer/VBoxContainer/HBoxContainer2/JasonLothamerCreditsLabel
]


func _ready():
	for credit_label in _credits_labels:
		credit_label.connect("meta_clicked", self, "_on_Label_meta_clicked")

func _on_Label_meta_clicked(meta):
	if meta != null:
		OS.shell_open(meta)
