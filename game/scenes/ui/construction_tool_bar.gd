extends Control

signal construction_tool_bar_clicked(structure_tile_type)

var _expanded := false
var _btns := []
var _animating := false
var _mouse_over_button := false
var _construction_button_group_size := Vector2(60, 74)

onready var _structure_tile_type_to_button := {
	StructureMgr.StructureTileType.Agriculture: $AgBtn,
	StructureMgr.StructureTileType.Education: $EducationBtn,
	StructureMgr.StructureTileType.Factory: $FactoryBtn,
	StructureMgr.StructureTileType.Medical: $MedicalBtn,
	StructureMgr.StructureTileType.Office: $OfficeBtn,
	StructureMgr.StructureTileType.Power: $PowerBtn,
	StructureMgr.StructureTileType.Reclamation: $ReclamationBtn,
	StructureMgr.StructureTileType.Recreation: $RecreationBtn,
	StructureMgr.StructureTileType.Residential: $ResidentialBtn,
	StructureMgr.StructureTileType.UUC: $UUCBtn,
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
onready var _menu_select_sound := $MenuSelectStreamPlayer

func _ready():
	SignalMgr.register_subscriber(self, "focused_gained", "_on_focused_gained")
	SignalMgr.register_publisher(self, "construction_tool_bar_clicked")
	#set("custom_StructureMgr/separation", -50)
	for c in get_children():
		if c.name.ends_with("Btn"):
			_btns.append(c)
	_btns.invert()
	for structure_tile_type in _structure_tile_type_to_button.keys():
		var btn = _structure_tile_type_to_button[structure_tile_type]
		btn.connect("button_down", self,"_on_button_down", [structure_tile_type])
		btn.connect("shortcut_activated", self,"_on_shortcut_activated", [structure_tile_type])
		btn.connect("mouse_entered", self, "_on_button_mouse_entered")
		btn.connect("mouse_exited", self, "_on_button_mouse_exited")
		btn.collapsed = true
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
		if !_mouse_over_button:
			_menu_close_sound.play()
		else:
			_mouse_over_button = false


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
	yield(get_tree().create_timer(.2),"timeout")
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	if resource_mgr.have_enough_resources_for_constructions(tile_type):
		emit_signal("construction_tool_bar_clicked", tile_type)
		_menu_select_sound.play()
		#_skip_next_menu_select_sound = true
	else:
		var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
		var structure_metadata := structure_mgr.get_structure_metadata(tile_type)
		HudAlertsMgr.add_hud_alert("Not enough resources to construct %s " % structure_metadata.get_name())

func _on_shortcut_activated(tile_type):
	_on_button_down(tile_type)

func _refresh_button_disable_states():
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	if resource_mgr == null:
		return
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


func _on_button_mouse_entered():
	_mouse_over_button = true

func _on_button_mouse_exited():
	_mouse_over_button = false


