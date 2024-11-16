extends Node3D

var game_time = 0.0;
var pulse_sources: Array[Vector4];
var pulse_sources_dirty = true;
var pulse_sources_tex: Texture2DRD = Texture2DRD.new();

var debug_enabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	RenderingServer.global_shader_parameter_set("pulse_sources", make_pulse_sources([]))
	
	_show_hint("Left click to chirp and see your surroundings", 2.0)
	_show_hint("Use WASD to fly around", 7.0)
	_show_hint("Space and control to fly up and down", 12.0)
	
func _set_hint_label_text(text: String):
	$UI/Hints/HintLabel.text = text

func _show_hint(text: String, delay: float = 0.0):
	var hint_tween = create_tween()
	hint_tween.tween_interval(delay)
	hint_tween.tween_callback(_set_hint_label_text.bind(text))
	hint_tween.tween_property($UI/Hints/HintLabel, "modulate:a", 1.0, 0.5)
	hint_tween.tween_interval(3.0)
	hint_tween.tween_property($UI/Hints/HintLabel, "modulate:a", 0.0, 0.5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Input.is_action_just_pressed("teleport_starting_point"):
		$Player.transform = $StartingPoint.transform
	if Input.is_action_just_pressed("teleport_outside"):
		$Player.transform = $Outside.transform
	
	if Input.is_action_just_pressed("debug_mode_toggle"):
		debug_enabled = !debug_enabled
		RenderingServer.global_shader_parameter_set("debug_enabled", debug_enabled)

	pulse_process(delta)

func pulse_process(delta):
	game_time += delta;
	RenderingServer.global_shader_parameter_set("game_time", game_time);

	# create pulses at static position
	#if game_time > chirp_pulse_last + 8:
		#chirp_pulse_last = game_time;
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.2));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.4));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.6));
		#dirty = true;

	if pulse_sources_dirty:
		# pulse update logic
		RenderingServer.global_shader_parameter_set("pulse_sources", make_pulse_sources(pulse_sources));
		pulse_sources_dirty = false;

func add_pulse(src: Vector3, start_time: float):
	pulse_sources.push_back(Vector4(src.x, src.y, src.z, start_time));
	pulse_sources_dirty = true;

func rm_old_pulses():
	var i = 0;
	while i < len(pulse_sources):
		if game_time - pulse_sources[i].w > 10:
			pulse_sources_dirty = true;
			pulse_sources.remove_at(i);
		else:
			i += 1;

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

func _on_chirp(pos: Vector3) -> void:
	add_pulse(pos, game_time)
