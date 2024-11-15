extends RigidBody3D

var velocity : Vector3

@export var base_speed : float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.velocity = Vector3(
		randf() * 2 - 1,
		(randf() * 2 - 1) / 10.0, # doesn't change vertical direction too much
		randf() * 2 - 1
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	self.move_and_collide(self.velocity * delta)
	
