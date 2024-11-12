extends Node3D

@onready var sphere : MeshInstance3D = $Sphere

var echo_material: ShaderMaterial

var pulse_sources: Array[Vector4];
var pulse_sources_tex: Texture2DRD = Texture2DRD.new();
var pulse_elapsed = 0;
var char_pulse_last = 3;
var chirp_pulse_last = 0;
var ambient = 0.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	echo_material = sphere.mesh.material;
	# initialize it
	echo_material.set_shader_parameter("pulse_sources", make_pulse_sources([]));


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# TODO: instead of 2 pulses from the camera every 2 seconds,
	# have something like space bar append a pulse position to pulse_sources
	# and trigger the code after "pulse update logic"
	pulse_elapsed += delta;
	echo_material.set_shader_parameter("pulse_elapsed", pulse_elapsed);

	var dirty = false;
	var i = 0;
	while i < len(pulse_sources):
		if pulse_sources[i].w - pulse_elapsed > 10:
			dirty = true;
			pulse_sources.remove_at(i);
		else:
			i += 1;

	if pulse_elapsed > char_pulse_last + 5:
		char_pulse_last = pulse_elapsed;
		var cam_pos = $Player/CameraRod/MainCamera.global_position;
		pulse_sources.push_back(Vector4(cam_pos.x, cam_pos.y, cam_pos.z, pulse_elapsed));
		pulse_sources.push_back(Vector4(cam_pos.x, cam_pos.y, cam_pos.z, pulse_elapsed + 0.5));
		dirty = true;
		
	if pulse_elapsed > chirp_pulse_last + 8:
		chirp_pulse_last = pulse_elapsed;
		pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, pulse_elapsed));
		pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, pulse_elapsed + 0.2));
		pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, pulse_elapsed + 0.4));
		pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, pulse_elapsed + 0.6));
		dirty = true;

	if dirty:
		# pulse update logic
		echo_material.set_shader_parameter("pulse_sources", make_pulse_sources(pulse_sources));

func update_ambient(v):
	if v != ambient:
		ambient = v;
		echo_material.set_shader_parameter("ambient", ambient)

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
