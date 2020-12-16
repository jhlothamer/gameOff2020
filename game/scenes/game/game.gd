class_name Game

extends Node2D

onready var _allowed_tiles_tile_map: TileMap = $AllowedTiles
onready var _structure_tiles_tile_map: TileMap = $Structures
onready var _structure_status_overlay_tiles_tile_map: TileMap = $StructuresStatusOverlay
onready var _separator_boxes_tile_map: TileMap = $SeperatorBoxes
onready var _damage_overlay_tile_map: TileMap = $DamageOverlay
onready var _resource_indicators_overlay_tile_map: TileMap = $ResourceIndicators
onready var _construction_repair_etc_animations_parent: Node2D = $ConstructionRepairEtcAnimations
onready var _power_overlay_tile_map: TileMap = $PoweredOverlay
onready var _placement_overlay_tile_map: TileMap = $PlacementOverlay

func _ready():
	Globals.set("_allowed_tiles_tile_map",_allowed_tiles_tile_map)
	Globals.set("_structure_tiles_tile_map",_structure_tiles_tile_map)
	Globals.set("_structure_status_overlay_tiles_tile_map",_structure_status_overlay_tiles_tile_map)
	Globals.set("_separator_boxes_tile_map",_separator_boxes_tile_map)
	Globals.set("_damage_overlay_tile_map",_damage_overlay_tile_map)
	Globals.set("_resource_indicators_overlay_tile_map",_resource_indicators_overlay_tile_map)
	Globals.set("_construction_repair_etc_animations_parent",_construction_repair_etc_animations_parent)
	Globals.set("_power_overlay_tile_map", _power_overlay_tile_map)
	Globals.set("_placement_overlay_tile_map", _placement_overlay_tile_map)


static func get_allowed_tiles_tile_map() -> TileMap:
	return Globals.get("_allowed_tiles_tile_map")


static func get_structure_tiles_tile_map() -> TileMap:
	return Globals.get("_structure_tiles_tile_map")


static func get_structure_status_overlay_tiles_tile_map() -> TileMap:
	return Globals.get("_structure_status_overlay_tiles_tile_map")


static func get_separator_boxes_tile_map() -> TileMap:
	return Globals.get("_separator_boxes_tile_map")


static func get_damage_overlay_tile_map() -> TileMap:
	return Globals.get("_damage_overlay_tile_map")


static func get_resource_indicators_overlay_tile_map() -> TileMap:
	return Globals.get("_resource_indicators_overlay_tile_map")


static func get_construction_repair_etc_animations_parent() -> Node2D:
	return Globals.get("_construction_repair_etc_animations_parent")


static func get_power_overlay_tile_map() -> TileMap:
	return Globals.get("_power_overlay_tile_map")


static func get_placement_overlay_tile_map() -> TileMap:
	return Globals.get("_placement_overlay_tile_map")

