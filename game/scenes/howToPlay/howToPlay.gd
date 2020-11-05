extends TextureRect

func _ready():
	var background_color = Globals.get("menusBackgroundColor")
	if background_color != null:
		self.self_modulate = background_color

