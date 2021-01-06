class_name ResourceMgr
extends Node

export var reclamation_enabled := true

func have_enough_resources_for_constructions(structure_type_id: int) -> bool:
	return false

func get_resource_amount(resource_name) -> float:
	return INF

func get_resource_amounts() -> Dictionary:
	return {}

func get_fragment_harvest_amount() -> float:
	return INF
