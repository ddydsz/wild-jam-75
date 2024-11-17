extends RigidBody3D

var velocity : Vector3
var direction_change_timer = 0.0

@export var base_speed : float = 5.0
@export var direction_change_interval = 0.2
@export var direction_change_max_angle_degrees = 3.0
@export var bobbing_frequency = 1.0
@export var bobbing_amplitude = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.velocity = random_direction() * base_speed

func _update_rotation():
	self.look_at(self.position + self.velocity.normalized(), Vector3.UP)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	$Mesh.position = Vector3(
		0.0, 
		sin(Time.get_ticks_msec() * bobbing_frequency) * bobbing_amplitude, 
		0.0)
	
	direction_change_timer += delta
	if direction_change_timer > direction_change_interval:
		direction_change_timer = 0.0
		self.velocity = self.velocity.rotated(
			Vector3.UP, randf() * deg_to_rad(direction_change_max_angle_degrees))
		_update_rotation()

func _physics_process(delta: float) -> void:	
	var collision = self.move_and_collide(self.velocity * delta)
	# if collided choose new direction
	if collision:
		var still_colliding = true
		var new_velocity : Vector3
		while still_colliding:
			new_velocity = random_direction() * base_speed
			if not self.move_and_collide(new_velocity, true): # not scaling by delta
				still_colliding = false 
		self.velocity = new_velocity
		_update_rotation()
		
func random_direction() -> Vector3:
	return Vector3(
		randf() * 2 - 1,
		0,
		randf() * 2 - 1
	).normalized()
	
func unalive():
	self.queue_free()
