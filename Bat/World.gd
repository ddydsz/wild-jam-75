extends Node3D

var echo_material: ShaderMaterial
var debug_material: StandardMaterial3D

@onready var bat_audio_player : AudioStreamPlayer = $Player/AudioStreamPlayer

var pulse_min_distance = 0.0;

const pulse_width = 0.15;
const pulse_max_range = 15.0;
const pulse_speed = 15.0;

var game_time = 0.0;
var pulse_sources: Array[Vector4];
var pulse_sources_tex: Texture2DRD = Texture2DRD.new();
# TODO: some way of triggering pulses that isn't just time based?
var char_pulse_last = 0.0;
var chirp_pulse_last = 0.0;

var debug_enabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	echo_material = load("res://Bat/Materials/echo_material.tres")
	debug_material = load("res://Bat/Materials/debug_material.tres")
	echo_material.set_shader_parameter("pulse_sounces", make_pulse_sources([]))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Input.is_action_just_pressed("teleport_starting_point"):
		$Player.transform = $StartingPoint.transform
	if Input.is_action_just_pressed("teleport_outside"):
		$Player.transform = $Outside.transform
	
	pulse_min_distance += delta * pulse_speed;
	if pulse_min_distance > pulse_max_range:
		pulse_min_distance = 0
		
	echo_material.set_shader_parameter("pulse_distance", pulse_min_distance)
	
	if Input.is_action_just_pressed("debug_mode_toggle"):
		debug_enabled = !debug_enabled
		if echo_material.get_shader_parameter("multipulse_enabled"):
			echo_material.set_shader_parameter("debug_enabled", debug_enabled)
		else:
			var cave_mi = $caves_02/cave as MeshInstance3D
			var ground_mi = $caves_02/ground as MeshInstance3D
			if debug_enabled:
				cave_mi.set_surface_override_material(0, debug_material)
				ground_mi.set_surface_override_material(0, debug_material)
			else:
				cave_mi.set_surface_override_material(0, echo_material)
				ground_mi.set_surface_override_material(0, echo_material)

	pulse_process(delta)

func pulse_process(delta):
	game_time += delta;
	echo_material.set_shader_parameter("pulse_elapsed", game_time);

	var dirty = false;
	var i = 0;
	while i < len(pulse_sources):
		if game_time - pulse_sources[i].w > 10:
			dirty = true;
			pulse_sources.remove_at(i);
		else:
			i += 1;

	if Input.is_action_just_pressed("action_chirp"):
		var cam_pos = $Player/CameraRod/MainCamera.global_position;
		pulse_sources.push_back(Vector4(cam_pos.x, cam_pos.y, cam_pos.z, game_time));
		dirty = true;
		bat_audio_player.play()
		
	# create pulses at player's position
	#if game_time > char_pulse_last + 5:
		#char_pulse_last = game_time;
		#var cam_pos = $Player/CameraRod/MainCamera.global_position;
		#pulse_sources.push_back(Vector4(cam_pos.x, cam_pos.y, cam_pos.z, game_time));
		#pulse_sources.push_back(Vector4(cam_pos.x, cam_pos.y, cam_pos.z, game_time + 0.5));
		#dirty = true;

	# create pulses at static position
	#if game_time > chirp_pulse_last + 8:
		#chirp_pulse_last = game_time;
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.2));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.4));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.6));
		#dirty = true;

	if dirty:
		# pulse update logic
		echo_material.set_shader_parameter("pulse_sources", make_pulse_sources(pulse_sources));

func make_pulse_sources(sources: Array[Vector4]):
	var fmt = RDTextureFormat.new();
	fmt.height = 1;
	# we have to have at least one pixel or godot errors at dev.texture_create
	fmt.width = len(sources) + 1;
	fmt.usage_bits |= RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT;
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT;
	var dev = RenderingServer.get_rendering_device();
	var data = PackedFloat32Array([0.0, 0.0, 0.0, 0.0]);
	for source in sources:
		data.push_back(source.x);
		data.push_back(source.y);
		data.push_back(source.z);
		data.push_back(source.w);
	#godot gives an error, so I guess we don't need to manually free this?
	#if (pulse_sources_tex.texture_rd_rid.is_valid()):
		#RenderingServer.get_rendering_device().free_rid(pulse_sources_tex.texture_rd_rid);
	pulse_sources_tex.texture_rd_rid = dev.texture_create(fmt, RDTextureView.new(), [data.to_byte_array()]);
	return pulse_sources_tex
