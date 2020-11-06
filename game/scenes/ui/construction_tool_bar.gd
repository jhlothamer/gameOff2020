extends Control

var _expanded := false
var _btns := []
var _animating := false

onready var _structure_tile_type_to_button := {
	Constants.StructureTileType.Agriculture: $AgBtn,
	Constants.StructureTileType.Education: $EducationBtn,
	Constants.StructureTileType.Factory: $FactoryBtn,
	Constants.StructureTileType.Medical: $MedicalBtn,
	Constants.StructureTileType.Office: $OfficeBtn,
	Constants.StructureTileType.Power: $PowerBtn,
	Constants.StructureTileType.Reclamation: $ReclamationBtn,
	Constants.StructureTileType.Recreation: $RecreationBtn,
	Constants.StructureTileType.Residential: $ResidentialBtn,
	Constants.StructureTileType.UUC: $UUCBtn,
}

onready var _skip_manual_animation_controls := [
	$ConstructionBtn,
	$OfficeBtn,
	$RecreationBtn
]

onready var _follow_x := {
	$ResidentialBtn: $OfficeBtn,
	$AgBtn: $OfficeBtn,
	$PowerBtn: $OfficeBtn,
	$UUCBtn: $OfficeBtn,
}

onready var _follow_y := {
	$UUCBtn: $MedicalBtn,
	$PowerBtn: $ReclamationBtn,
	$AgBtn:  $FactoryBtn,
	$ResidentialBtn: $RecreationBtn
}

onready var _animation_player: AnimationPlayer = $AnimationPlayer
onready var _construction_btn: TextureButton = $ConstructionBtn

func _ready():
	SignalMgr.register_subscriber(self, "focused_gained", "_on_focused_gained")
	set("custom_constants/separation", -50)
	for c in get_children():
		if c.name.ends_with("Btn"):
			_btns.append(c)
	_btns.invert()
	
	for structure_tile_type in _structure_tile_type_to_button.keys():
		var btn = _structure_tile_type_to_button[structure_tile_type]
		btn.connect("pressed", self, "_on_Button_pressed", [structure_tile_type])
	

func _on_focused_gained(control):
	if _expanded:
		_expanded = false
		_construction_btn.pressed = false
		_animation_player.play_backwards("expand")

func _on_ConstructionBtn_toggled(button_pressed):
	if button_pressed:
		_expanded = true
		_animation_player.play("expand")
	else:
		_expanded = false
		_construction_btn.pressed = false
		_animation_player.play_backwards("expand")


func _on_ConstructionBtn_focus_exited():
	if !_expanded:
		return
	_expanded = false
	_construction_btn.pressed = false
	_animation_player.play_backwards("expand")


func _on_AnimationPlayer_animation_finished(anim_name):
	_animating =  false
	if !_expanded:
		for i in range(2, _btns.size()):
			_btns[i].rect_position = Vector2.ZERO


func _on_AnimationPlayer_animation_started(anim_name):
	_animating = true


func _process(_delta):
	if !_animating:
		return
	for i in range(_btns.size()):
		if _skip_manual_animation_controls.has(_btns[i]):
			continue
		if _follow_y.has(_btns[i]):
			_btns[i].rect_position.y = _follow_y[_btns[i]].rect_position.y
		else:
			var dy = abs(_btns[i - 1].rect_position.y - _btns[i-2].rect_position.y)
			_btns[i].rect_position.y = _btns[i - 1].rect_position.y - dy
		if _follow_x.has(_btns[i]):
			_btns[i].rect_position.x = _follow_x[_btns[i]].rect_position.x



func _on_Button_pressed(tile_type):
	print("clicked on structure button of type " + str(tile_type))
