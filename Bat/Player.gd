extends CharacterBody3D

class_name PlayerCamera

signal hit
signal got_food(amount: float)
signal chirp(pos: Vector3)
signal hint_enemies
signal hint_go_outside
signal hint_outside

# Nodes
@onready var camera_pivot : Node3D = self
@onready var camera_rod : Node3D = get_node("CameraRod")
@onready var camera : Camera3D = get_node("CameraRod/MainCamera")

# Movement
@export var mouse_sensitivity : float = 0.15
@export var camera_min_vertical_rotation : float = -85.0
@export var camera_max_vertical_rotation : float = 85.0

# There are reasons why we can't use something like self.rotation that I'm not
# prepared to explain right now.
var camera_rotation : Vector2 = Vector2.ZERO
var camera_target_rotation : Vector2 = Vector2(0.0, PI / 2.0)

@export var camera_rotation_smoothing_speed : float = 0.5

# zooming
@export var camera_zoom : float = 3.0 : set = set_camera_zoom
func set_camera_zoom(value): camera_zoom = clamp(value, camera_min_zoom_distance, camera_max_zoom_distance)
@export var camera_min_zoom_distance : float = 3.0
@export var camera_max_zoom_distance : float = 15.0
@export var camera_zoom_step : float = 0.5

# Cursor
@onready var is_cursor_visible : get = get_is_cursor_visible, set = set_is_cursor_visible
func set_is_cursor_visible(value): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED)
func get_is_cursor_visible(): return Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE
@export var push_back_force: float = 5.0;

@export var speed = 6.0
@export var friction = 0.97

var SIN_WAVE_TIME_DIVISION: float = 100;
var SIN_WAVE_AMPLITUDE_DIVISION: float = 65;

var food_amount : float = 0.0;
var max_food_amount : float = 100.0;

#####################
#  Default methods  #
#####################

func _ready() -> void:
	self.is_cursor_visible = false

func _process(delta: float) -> void:
	process_basic_input()
	
	# bobbing up and down from wing flapping
	camera.translate(Vector3(0, sin(float(Time.get_ticks_msec())/SIN_WAVE_TIME_DIVISION)/SIN_WAVE_AMPLITUDE_DIVISION, 0))
	
	# gradually rotate camera towards target direction
	self.camera_rotation.y = lerp(
		self.camera_rotation.y, 
		self.camera_target_rotation.y, 
		self.camera_rotation_smoothing_speed * delta)
	self.camera_rotation.x = lerp(
		self.camera_rotation.x, 
		self.camera_target_rotation.x, 
		self.camera_rotation_smoothing_speed * delta)
		
	self.rotation.y = self.camera_rotation.y
	camera_rod.rotation.x = self.camera_rotation.x

func _physics_process(delta: float) -> void:
	
	# friction
	self.velocity *= friction
	
	var d = delta * speed
	
	if Input.is_action_pressed("ui_up"):
		self.velocity += - $CameraRod/MainCamera.global_transform.basis.z * d
	if Input.is_action_pressed("ui_down"):
		self.velocity += $CameraRod/MainCamera.global_transform.basis.z * d
	if Input.is_action_pressed("ui_right"):
		self.velocity += $CameraRod/MainCamera.global_transform.basis.x * d
	if Input.is_action_pressed("ui_left"):
		self.velocity += - $CameraRod/MainCamera.global_transform.basis.x * d
	if Input.is_action_pressed("action_jump"):
		self.velocity += $CameraRod/MainCamera.global_transform.basis.y * d
	if Input.is_action_pressed("action_down"):
		self.velocity += - $CameraRod/MainCamera.global_transform.basis.y * d
	if Input.is_action_just_pressed("action_chirp"):
		chirp.emit(self.global_position)
		$ChirpPlayer.play()

	self.move_and_slide()
		
func _unhandled_input(event: InputEvent) -> void:
	process_mouse_input(event)

func toggle_cursor_visibility() -> void:
	self.is_cursor_visible = !self.is_cursor_visible

###################
#  Input methods  #
###################

func process_basic_input():
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_cursor_visibility()

func process_mouse_input(event : InputEvent) -> void:
	
	# Cursor movement
	if event is InputEventMouseMotion:
		
		var rot_y = deg_to_rad(event.relative.x * mouse_sensitivity)
		var rot_x = deg_to_rad(event.relative.y * mouse_sensitivity)
		
		# Limit vertical rotation
		self.camera_target_rotation.x = clamp(
			self.camera_target_rotation.x - rot_x,
			deg_to_rad(camera_min_vertical_rotation),
			deg_to_rad(camera_max_vertical_rotation))
		self.camera_target_rotation.y = self.camera_target_rotation.y - rot_y
		
		#print("target_rotation_x: ", self.camera_target_rotation.x)
		#print("target_rotation_y: ", self.camera_target_rotation.y)
	
	# Scrolling
	elif event is InputEventMouseButton:
		if event.is_pressed() and not self.is_cursor_visible:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				self.camera_zoom -= camera_zoom_step
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				self.camera_zoom += camera_zoom_step


func take_damage():
	$DamageTakenPlayer.play()
	hit.emit()

func get_food():
	$MunchPlayer.play()

func _on_area_3d_body_entered(body: Node3D):
	if body.is_in_group("mushroom1") || body.is_in_group("spiders"):
		var force_direction: Vector3 = (self.global_position - body.global_position)
		self.velocity += force_direction.normalized() * push_back_force
		take_damage()
	elif body.is_in_group("grasshoppers") && body.alive:
		body.unalive()
		get_food()
		got_food.emit(10.0)
	elif body.is_in_group("moths"):
		body.unalive()
		get_food()
		got_food.emit(10.0)

func _on_area_3d_area_shape_entered(area_rid: RID, area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	if area.is_in_group("hint_enemies"):
		hint_enemies.emit()
	elif area.is_in_group("hint_go_outside"):
		hint_go_outside.emit()
	elif area.is_in_group("hint_outside"):
		var reverb: AudioEffectReverb = AudioServer.get_bus_effect(0, 0)
		reverb.room_size = 1.0
		reverb.dry = 1.0
		reverb.wet = 0.0
		hint_outside.emit()
	elif area.is_in_group("hint_inside"):
		var reverb: AudioEffectReverb = AudioServer.get_bus_effect(0, 0)
		reverb.room_size = 0.5
		reverb.dry = 0.6
		reverb.wet = 0.4
