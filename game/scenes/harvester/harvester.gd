tool
extends Node2D

signal harvester_active()
signal harvester_inactive()

enum HarvesterState {
	IDLE,
	TRAVELING,
	HARVESTING,
	RETURNING_TO_BARN
}

export (float, 1.0, 100000.0) var path_radius := 100.0 setget _set_path_radius
export (float, .0, 10000.0) var linear_speed := 100.0
export (float, .1, 100.0) var harvest_time_per_fragment := 1.4
export (float, -180.0, 180.0) var harvester_barn_direction_degrees := 0.0
export (float, 1.0, 100.0) var harvester_barn_direction_tolerance_degrees := 5.0
export (float, 1.0, 10000.0) var distance_from_moon_tolerance := 200.0
export var debug := true


onready var _body := $KinematicBody2D
onready var _animation_player := $AnimationPlayer
onready var _animated_sprite := $KinematicBody2D/AnimatedSprite
onready var _particles := $KinematicBody2D/AnimatedSprite/SprayParticles2D
onready var _chunk_particles := $KinematicBody2D/AnimatedSprite/ChunkParticles2D
onready var _harvesting_sound := $KinematicBody2D/HarvestingSound

var _position_degrees := 0.0
var _speed_radians := 0.0
var _fragment_contact_count := 0
var _current_fragement
var _fragment_harvest_times := {}
var _harvester_state :int = HarvesterState.IDLE
var _travel_direction := 1.0
var _harvester_barn_direction_radians := 0.0
var _harvester_barn_direction_tolerance_radians := 0.0
var _distance_from_moon_tolerance_sq := 0
var _fragment_harvest_amount := 0.0
var _harvest_ore_label_class := preload("res://scenes/harvester/havest_ore_label.tscn")

func _ready():
	SignalMgr.register_subscriber(self, "harvester_activated", "_on_harvester_activated")
	SignalMgr.register_publisher(self, "harvester_active")
	SignalMgr.register_publisher(self, "harvester_inactive")
	if !Engine.editor_hint:
		_body.position.y -= path_radius
	_speed_radians = linear_speed / path_radius
	_harvester_barn_direction_radians = deg2rad(harvester_barn_direction_degrees)
	_harvester_barn_direction_tolerance_radians = deg2rad(harvester_barn_direction_tolerance_degrees)
	_distance_from_moon_tolerance_sq = distance_from_moon_tolerance * distance_from_moon_tolerance

func _set_path_radius(value: float) -> void:
	path_radius = value
	if _body != null and Engine.editor_hint:
		_body.position.y -= value


func _process(delta: float) -> void:
	if Engine.editor_hint:
		return
	
	if _harvester_state == HarvesterState.TRAVELING:
		rotation += delta*_speed_radians*_travel_direction
		if !_update_travel_direction():
			_harvester_state = HarvesterState.RETURNING_TO_BARN
			emit_signal("harvester_inactive")
			HudAlertsMgr.add_hud_alert("Harvester returning to barn")
	if _harvester_state == HarvesterState.RETURNING_TO_BARN:
		rotation += delta*_speed_radians*_travel_direction
		if _is_at_barn_location(delta*_speed_radians):
			_harvester_state = HarvesterState.IDLE
		
	
	if _current_fragement != null:
		var current_fragment_harvest_time = _fragment_harvest_times[_current_fragement] + delta
		if current_fragment_harvest_time >= harvest_time_per_fragment:
			var spawn_mgr := SpawnMgr.get_spawn_mgr()
			spawn_mgr.remove_fragment(_current_fragement)
			_spawn_havest_ore_label()
			_fragment_harvest_times.erase(_current_fragement)
			_current_fragement = null
			_harvester_state = HarvesterState.TRAVELING
		else:
			_fragment_harvest_times[_current_fragement] = current_fragment_harvest_time



func _on_FragmentDetectArea_body_entered(body):
	if body.is_in_group("fragment"):
		_fragment_contact_count += 1
		
		if body != _current_fragement:
			_current_fragement = body
			if !_fragment_harvest_times.has(body):
				_fragment_harvest_times[body] = 0.0
		
		if _harvester_state == HarvesterState.TRAVELING:
			_harvester_state = HarvesterState.HARVESTING
			_animation_player.stop()
			_animated_sprite.play()
			_harvesting_sound.play()
			_particles.emitting = true
			_chunk_particles.emitting = true


func _on_FragmentDetectArea_body_exited(body):
	if body.is_in_group("fragment"):
		_fragment_contact_count = max(_fragment_contact_count - 1, 0)
		if body == _current_fragement:
#			var spawn_mgr := SpawnMgr.get_spawn_mgr()
#			spawn_mgr.remove_fragment(_current_fragement)
			_current_fragement = null
			#force to travel - don't want harvest to get stuck
			_fragment_contact_count = 0
		if _fragment_contact_count < 1:
			_harvester_state = HarvesterState.TRAVELING
			_animated_sprite.stop()
			_particles.emitting = false
			_chunk_particles.emitting = false
			_animation_player.play("spin_wheels")


func _update_harvester_animation_direction():
	_body.scale.x = _travel_direction


func _on_harvester_activated() -> void:
	if [HarvesterState.TRAVELING, HarvesterState.HARVESTING].has(_harvester_state):
		HudAlertsMgr.add_hud_alert("Harvester already deployed")
		if debug:
			print("Harvester: harvester_activated signal received by current state is " + EnumUtil.get_string(HarvesterState, _harvester_state))
		return

	if _update_travel_direction():
		_harvester_state = HarvesterState.TRAVELING
		emit_signal("harvester_active")
		HudAlertsMgr.add_hud_alert("Deploying harvester")
		if debug:
			print("Harvester: harvester_activated signal received.  Harvester now active.  Current state is " + EnumUtil.get_string(HarvesterState, _harvester_state))
	else:
		HudAlertsMgr.add_hud_alert("Nothing currently on surface to harvest")
		if debug:
			print("Harvester: harvester_activated signal received by but nothing to harvest.  Current state is " + EnumUtil.get_string(HarvesterState, _harvester_state))
			print("Harvester: distance_from_moon_tolerance = " + str(distance_from_moon_tolerance))
			print("Harvester: distance_from_moon_tolerance squared = " + str(_distance_from_moon_tolerance_sq))
			var distance = global_position.distance_to(_body.global_position)
			var distance_sq = global_position.distance_squared_to(_body.global_position)
			print("Harvester: distance of body to center: " + str(distance))
			print("Harvester: distance of body to center (squared): " + str(distance_sq))
			var spawn_mgr := SpawnMgr.get_spawn_mgr()
			if spawn_mgr == null:
				print("Harvester: spawn manager is null!!")
			else:
				var fragments = spawn_mgr.fragments
				if fragments == null or fragments.size() == 0:
					print("Harvester: no fragments exist to consider.")
					return
				var fragment_close_count := 0
				for fragment in fragments:
					var frag_distance = global_position.distance_to(fragment.global_position)
					var frag_distance_sq = global_position.distance_squared_to(fragment.global_position)
					if _approx_eq(frag_distance_sq, distance_sq, _distance_from_moon_tolerance_sq):
						print("Harvester: at least 1 fragment close enough to harvest - by distance squared.")
						fragment_close_count += 1
						break
					if _approx_eq(frag_distance, distance, distance_from_moon_tolerance):
						print("Harvester: at least 1 fragment close enough to harvest.")
						print("Harvester: fragment distance is " + str(frag_distance))
						print("Harvester: fragment distance squared is " + str(frag_distance_sq))
						fragment_close_count += 1
						break
				if fragment_close_count == 0:
					print("Harvester:  No fragments close enough to harvest.")

	

func _update_travel_direction() -> bool:
	var spawn_mgr := SpawnMgr.get_spawn_mgr()
	if spawn_mgr == null:
		return false
	var fragments = spawn_mgr.fragments
	if fragments == null || fragments.size() < 1:
		return false
	
	var closest_angle_to := rotation + PI
	var vector_to_body = _body.global_position - global_position
	var body_distance = global_position.distance_to(_body.global_position)
	var fragments_considered_count := 0
	for fragment in fragments:
		var fragment_distance = global_position.distance_to(fragment.global_position)
		if !_approx_eq(body_distance, fragment_distance, distance_from_moon_tolerance):
			continue
		fragments_considered_count += 1
		#var angle_to = Vector2Util.closest_angle_to(_body.global_position - global_position, fragment.global_position - global_position)
		var angle_to = vector_to_body.angle_to(fragment.global_position - global_position)
		if abs(angle_to) < abs(closest_angle_to):
			closest_angle_to = angle_to

	if fragments_considered_count == 0:
		return false
	
	var previous_travel_direciton := _travel_direction
	if closest_angle_to > 0.0:
		_travel_direction = 1.0
	else:
		_travel_direction = -1.0
	
	if previous_travel_direciton != _travel_direction:
		_update_harvester_animation_direction()
	
	return true

func _is_at_barn_location(delta_radians: float) -> bool:
	var rot = global_position.angle_to_point(_body.global_position)
	return rot >= _harvester_barn_direction_radians - _harvester_barn_direction_tolerance_radians and rot <= _harvester_barn_direction_radians + _harvester_barn_direction_tolerance_radians

func _approx_eq(a: float, b: float, tolerance: float) -> bool:
	return abs(a - b) <= tolerance

func _get_fragment_harvest_amount() -> float:
	if _fragment_harvest_amount <= 0.0:
		var resource_mgr = ResourceMgr.get_resource_mgr()
		_fragment_harvest_amount = resource_mgr.get_fragment_harvest_amount()
	return _fragment_harvest_amount

func _spawn_havest_ore_label():
	var harvest_ore_label = _harvest_ore_label_class.instance()
	var parent = Game.get_construction_repair_etc_animations_parent()
	harvest_ore_label.fragment_harvest_amount = _get_fragment_harvest_amount()
	parent.add_child(harvest_ore_label)
	harvest_ore_label.global_position = _body.global_position
