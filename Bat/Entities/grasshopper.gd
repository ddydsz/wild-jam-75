extends RigidBody3D

signal chirp(pos: Vector3);

var scared = false;
var alive = true;
var sleep_contact_point: Vector3;

# change material when grasshopper is unalived
var unalive_material = load("res://Bat/Materials/water.tres")

func _ready() -> void:
	$Timer.start()

func _process(_delta: float) -> void:
	pass

func _on_timer_timeout():
	if self.sleeping == true && randf() > 0.0:
		var jump_dir = self.basis.y
		if sleep_contact_point != null:
			jump_dir = (self.global_position - sleep_contact_point).normalized()
		self.apply_impulse(jump_dir * 5.0)
	$Timer.start()
	chirp.emit(self.position)

func unalive():
	self.sleeping = false;
	self.alive = false
	$grasshopper_mesh/Cricket.set_surface_override_material(0, unalive_material)
	$Timer.stop()
	
func set_scared(s: bool):
	if s:
		$Timer.stop();
	else:
		$Timer.start();
	scared = s;

func _on_body_entered(body: Node) -> void:
	if self.alive && body is StaticBody3D:
		var state: PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(self.get_rid())
		sleep_contact_point = state.get_contact_collider_position(0)
		self.sleeping = true
