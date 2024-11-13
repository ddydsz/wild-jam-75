extends Node3D

var echo_material: ShaderMaterial
var debug_material: StandardMaterial3D

@onready var bat_audio_player : AudioStreamPlayer = $Player/AudioStreamPlayer

var pulse_min_distance = 0.0;

const pulse_width = 0.15;
const pulse_max_range = 15.0;
const pulse_speed = 15.0;

var debug_enabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	echo_material = load("res://Bat/Materials/echo_material.tres")
	debug_material = load("res://Bat/Materials/debug_material.tres")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pulse_min_distance += delta * pulse_speed;
	if pulse_min_distance > pulse_max_range:
		pulse_min_distance = 0
		bat_audio_player.play()
		
	echo_material.set_shader_parameter("pulse_distance", pulse_min_distance)
	
	if Input.is_action_just_pressed("debug_mode_toggle"):
		debug_enabled = !debug_enabled	
		var cave_mi = $caves_02/cave as MeshInstance3D
		var ground_mi = $caves_02/ground as MeshInstance3D
		if debug_enabled:	
			cave_mi.set_surface_override_material(0, debug_material)
			ground_mi.set_surface_override_material(0, debug_material)
		else:
			cave_mi.set_surface_override_material(0, echo_material)
			ground_mi.set_surface_override_material(0, echo_material)
