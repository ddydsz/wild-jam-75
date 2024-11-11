extends Node3D

@onready var sphere : MeshInstance3D = $Sphere

var echo_material: ShaderMaterial

var pulse_min_distance = 0.0;

const pulse_width = 0.15;
const pulse_max_range = 15.0;
const pulse_speed = 15.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	echo_material = sphere.mesh.material;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pulse_min_distance += delta * pulse_speed;
	if pulse_min_distance > pulse_max_range:
		pulse_min_distance = 0
		
	echo_material.set_shader_parameter("pulse_distance", pulse_min_distance)
