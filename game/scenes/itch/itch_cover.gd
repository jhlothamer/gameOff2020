extends Control


export (float, 0.0, 2.0) var resize_factor : float = .5

onready var _texture_rect := $TextureRect
onready var _animation_player := $AnimationPlayer

const crop_size := Vector2(630,500)
const drop_frame := 8

var _capture := false
var _frame_counter := 0
var _directory_name := ""
var _file_counter := 0

var _user_data_directory : Directory = Directory.new()

func _ready():
	_user_data_directory.open("user://")
	OS.window_fullscreen = false
	_texture_rect.visible = false

	_directory_name = get_date_time_string()
	_file_counter = 0
	_user_data_directory.make_dir(_directory_name)


func get_date_time_string():
	# year, month, day, weekday, dst (daylight savings time), hour, minute, second.
	var datetime = OS.get_datetime()
	return String(datetime["year"]) + i_to_padded(datetime["month"],2) + i_to_padded(datetime["day"],2) + "_" + i_to_padded(datetime["hour"],2) + i_to_padded(datetime["minute"],2) + i_to_padded(datetime["second"],2)

func i_to_padded(i : int, digits: int) -> String:
	return String(i).pad_zeros(digits)

func _on_AnimationPlayer_animation_started(anim_name):
	_capture = true
	print("capture started")


func _on_AnimationPlayer_animation_finished(anim_name):
	_capture = false
	print("capture ended")


func _process(delta):
	if !_capture:
		return
	
	var take_image := _frame_counter % drop_frame != 0
	
	_frame_counter += 1
	if !take_image:
		return
	
	var image: Image = get_viewport().get_texture().get_data()
	image.flip_y()
	if resize_factor != 1.0:
		var original_size = image.get_size()
		image.resize(original_size.x*resize_factor, original_size.y*resize_factor, Image.INTERPOLATE_BILINEAR)
	image.crop(crop_size.x*resize_factor, crop_size.y*resize_factor)
	image.save_png("user://" + _directory_name + "/" + i_to_padded(_file_counter,4) + ".png")
	_file_counter += 1
	



func _on_DelayTimer_timeout():
	_animation_player.play("ItchCoverAnimation 2")
