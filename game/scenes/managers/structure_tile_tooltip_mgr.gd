extends Node2D

export var tooltip_wait := 2.0
export var debug := false

signal pop_tile_tooltip(screen_coord, structure)
signal hide_tile_tooltip()

onready var tooltip_wait_timer := $TooltipWaitTimer

var _current_structure: StructureMgr.StructureData
var _panning_camera := false

func _ready():
	SignalMgr.register_publisher(self, "pop_tile_tooltip")
	SignalMgr.register_publisher(self, "hide_tile_tooltip")
	SignalMgr.register_subscriber(self, "camera_pan_started", "_on_camera_pan_started")
	SignalMgr.register_subscriber(self, "camera_pan_stopped", "_on_camera_pan_stopped")
	SignalMgr.register_subscriber(self, "tile_tooltip_auto_closed", "_on_tile_tooltip_auto_closed")
	tooltip_wait_timer.wait_time = tooltip_wait


func _unhandled_input(event):
	if !event is InputEventMouseMotion or _panning_camera:
		return
	var mouse_global_position = get_global_mouse_position()
	var structure_mgr: StructureMgr = ServiceMgr.get_service(StructureMgr)
	var structure:StructureMgr.StructureData = structure_mgr.get_structure_at_world_coord(mouse_global_position)
	if structure == null:
		if debug and _current_structure:
			print("StructureTileTooltipMgr: hide_tile_tooltip emitted")
		_current_structure = null
		emit_signal("hide_tile_tooltip")
		if tooltip_wait_timer.is_stopped():
			tooltip_wait_timer.stop()
	elif structure != _current_structure:
		_current_structure = structure
		tooltip_wait_timer.start()
		if debug:
			print("StructureTileTooltipMgr: tooltip wait timer started")

func _on_TooltipWaitTimer_timeout():
	if debug:
		print("StructureTileTooltipMgr: wait timer expired.  Showing tooltip")
	var mouse_screen_coord = get_viewport().get_mouse_position()
	if _current_structure != null:
		emit_signal("pop_tile_tooltip", mouse_screen_coord, _current_structure)
	elif debug:
		print("StructureTileTooltipMgr: no current structure - did not show tooltip")


func _on_tile_tooltip_auto_closed():
	_current_structure = null

func _on_camera_pan_started():
	_current_structure = null
	_panning_camera = true
	tooltip_wait_timer.stop()
	emit_signal("hide_tile_tooltip")

func _on_camera_pan_stopped():
	_panning_camera = false

