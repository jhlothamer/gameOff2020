extends Control

signal construction_tool_bar_clicked(structure_tile_type)

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

onready var _menu_open_sound := $MenuOpenStreamPlayer
onready var _menu_close_sound := $MenuCloseStreamPlayer
onready var _menu_mouse_over_sound := $MenuMouseOverStreamPlayer

func _ready():
	SignalMgr.register_subscriber(self, "focused_gained", "_on_focused_gained")
	SignalMgr.register_publisher(self, "construction_tool_bar_clicked")
	#set("custom_constants/separation", -50)
	for c in get_children():
		if c.name.ends_with("Btn"):
			_btns.append(c)
	_btns.invert()
	for structure_tile_type in _structure_tile_type_to_button.keys():
		var btn = _structure_tile_type_to_button[structure_tile_type]
		btn.connect("button_down", self,"_on_button_down", [structure_tile_type])
	_set_construction_button_labels_visibility(false)
	

func _on_focused_gained(_control):
	if _expanded:
		_expanded = false
		_construction_btn.pressed = false
		_set_construction_button_labels_visibility(false)
		_animation_player.play_backwards("expand")

func _on_ConstructionBtn_toggled(button_pressed):
	if button_pressed:
		_expanded = true
		_refresh_button_disable_states()
		_set_construction_button_labels_visibility(true)
		_animation_player.play("expand")
		_menu_open_sound.play()
	else:
		_expanded = false
		_construction_btn.pressed = false
		_set_construction_button_labels_visibility(false)
		_animation_player.play_backwards("expand")
		_menu_close_sound.play()


func _on_ConstructionBtn_focus_exited():
	if !_expanded:
		return
	_expanded = false
	_construction_btn.pressed = false
	_animation_player.play_backwards("expand")


func _on_AnimationPlayer_animation_finished(_anim_name):
	_animating =  false
	if !_expanded:
		for i in range(2, _btns.size()):
			_btns[i].rect_position = Vector2.ZERO
			_btns[i].collapsed = true
		_btns[1].collapsed = true
		


func _on_AnimationPlayer_animation_started(_anim_name):
	_animating = true


func _process(_delta):
	if !_animating:
		return
	for i in range(_btns.size()):
		var btn = _btns[i]
		if _skip_manual_animation_controls.has(btn):
			continue
		if _follow_y.has(btn):
			var follow_y_btn = _follow_y[_btns[i]]
			btn.rect_position.y = follow_y_btn.rect_position.y
		else:
			var dy = abs(_btns[i - 1].rect_position.y - _btns[i-2].rect_position.y)
			btn.rect_position.y = _btns[i - 1].rect_position.y - dy
		if _follow_x.has(btn):
			var follow_x_btn = _follow_x[_btns[i]]
			btn.rect_position.x = follow_x_btn.rect_position.x


func _on_button_down(tile_type):
	#print("clicked on structure button of type " + str(tile_type))
	yield(get_tree().create_timer(.2),"timeout")
	var resource_mgr := ResourceMgr.get_resource_mgr()
	if resource_mgr.have_enough_resources_for_constructions(tile_type):
		emit_signal("construction_tool_bar_clicked", tile_type)
	else:
		print("didn't have enough resource in end - play sound and/or show message")


func _refresh_button_disable_states():
	var resource_mgr:ResourceMgr = Globals.get("ResourceMgr")
	for structure_type_id in _structure_tile_type_to_button.keys():
		var btn = _structure_tile_type_to_button[structure_type_id]
		btn.disabled = !resource_mgr.have_enough_resources_for_constructions(structure_type_id)
		btn.collapsed = false

func _set_construction_button_labels_visibility(is_visible: bool) -> void:
	for btn in _structure_tile_type_to_button.values():
		btn.label_visible = is_visible




func _on_ConstructionToolBar_mouse_entered():
	#_menu_mouse_over_sound.play()
	pass
