extends Node
var checked = false
onready var asteroid_scene = preload("res://scenes/game/Asteroid.tscn")
var asteroids = []
var fragments = []
var asteroid_sprites = []
var fragment_sprites = []
var spawn_extents_min = Vector2(-13233,-9203.9)
var spawn_extents_max = Vector2(13233,9203.9)

onready var fragment_scene = preload("res://scenes/game/Fragment.tscn")
export var min_time_between_asteroids = 1 #seconds
export var max_time_between_asteroids = 5

# how many asteroids can exist in scene at once
export var max_concurrent_asteroids = 20

var spawning_allowed = false

# how many segments are launched after collision
export var min_asteroid_segments: int = 2
export var max_asteroid_segments: int = 5
export var fragment_limit = 200
# how much variance in the change in velocity by which they are ejected
export var fragment_propel_variance_min = 0.4
export var fragment_propel_variance_max = 0.8

func _ready():
	spawn_extents_min.x = get_parent().get_node("CameraLimitsRect").rect_global_position.x
	spawn_extents_min.y = get_parent().get_node("CameraLimitsRect").rect_global_position.y
	spawn_extents_max.x = abs(get_parent().get_node("CameraLimitsRect").rect_global_position.x)
	spawn_extents_max.y = abs(get_parent().get_node("CameraLimitsRect").rect_global_position.y)
	_load_sprites("res://assets/images/asteroids", asteroid_sprites)
	_load_sprites("res://assets/images/asteroids/fragments", fragment_sprites )
	if asteroid_sprites.empty():
		print("errror loading asteroid sprites")
	else:
		_start_spawn_timer()
		spawning_allowed = true
		
func _process(delta):
	if fragments.size() > fragment_limit:
		var to_remove = fragments[0]
		fragments.erase(to_remove)
		to_remove.queue_free()
	for i in asteroids:
		if _is_out_of_bounds(i):
			i.queue_free()
			asteroids.erase(i)
			print("asteroid out of bounds, despawning")
	for i in fragments:
		if _is_out_of_bounds(i):
			i.queue_free()
			fragments.erase(i)
			print("fragment out of bounds, despawning")

func _is_out_of_bounds(body):
	if body.global_position.x > spawn_extents_max.x or \
		body.global_position.x < spawn_extents_min.x or \
		body.global_position.y > spawn_extents_max.y or \
		body.global_position.y < spawn_extents_min.y:
			return true
	return false

func _spawn_asteroid():
	if spawning_allowed:
		if asteroids.size() >= max_concurrent_asteroids:
			_start_spawn_timer()
			return
		else:
			var asteroid = asteroid_scene.instance()
			asteroid.get_node("Sprite").texture = ArrayUtil.get_rand(asteroid_sprites)
			var spawn_pos = Vector2(7500,0)
			if randi() % 2 == 0:
				#spawn along top or bottom
				if randi() % 2 == 0:
					#spawn top
					spawn_pos.y = spawn_extents_min.y + 100
				else:
					#spawn bottom
					spawn_pos.y = spawn_extents_max.y - 100
				spawn_pos.x = rand_range((spawn_extents_max.x / 2) + 100, spawn_extents_max.x - 100)
			else:
				#spawn right side
				spawn_pos.x = spawn_extents_max.x - 100
				spawn_pos.y = rand_range(spawn_extents_min.y + 100, spawn_extents_max.y - 100)
			var initial_kick = spawn_pos.direction_to(Vector2(0,0)).rotated(rand_range(-135,135))
			initial_kick = initial_kick * rand_range( 500, 3000)
			asteroid.position = spawn_pos
			asteroids.append(asteroid)
			# delay kick to let physics body settle after spawning
			asteroid.delayed_kick_offset = Vector2(rand_range(0,50),rand_range(0,50))
			asteroid.delayed_kick_impulse = initial_kick
			add_child(asteroid)
			print("added asteroid at " + str(spawn_pos))

func _start_spawn_timer():
	$AsteroidTimer.wait_time = rand_range(min_time_between_asteroids,max_time_between_asteroids)
	$AsteroidTimer.start()

func _load_sprites(path, array):
	var direc = Directory.new()
	direc.open(path)
	direc.list_dir_begin()
	while true:
		var FileName = direc.get_next()
		if FileName == "":
			break
		elif !FileName.begins_with(".") and !FileName.ends_with(".import"):
			array.append(load(path + "/" + FileName))
	direc.list_dir_end()
	
func _on_AsteroidTimer_timeout():
	if !spawning_allowed:
		$AsteroidTimer.stop()
		return
	_spawn_asteroid()
	_start_spawn_timer()

func _asteroid_impact(body : RigidBody2D ):
	body._mark_for_disintegration()

func _disintegrate(body):
	# create a random number of debris parts
	# some will eject off into space
	# some will form an orbit "ring" around the moon
	# some will settle on the surface.
	# TODO: base number of fragments on random asteroid size?
	var segments = int(rand_range(min_asteroid_segments,max_asteroid_segments))
	for i in range(0,segments):
		var new_fragment = fragment_scene.instance()
		#kick it
		new_fragment.position = body.position
		new_fragment.linear_velocity = \
			body.linear_velocity.rotated(rand_range(-45,45))
		new_fragment.linear_velocity = new_fragment.linear_velocity * \
			rand_range(fragment_propel_variance_min, fragment_propel_variance_max)
		new_fragment.angular_velocity = body.angular_velocity \
			+ rand_range(-20,20)
		fragments.append(new_fragment)
		add_child(new_fragment)
	asteroids.erase(body)
	body.queue_free()

