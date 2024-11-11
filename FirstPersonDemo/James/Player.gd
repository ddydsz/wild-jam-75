extends CharacterBody3D

const LERP_VALUE : float = 0.05

var snap_vector : Vector3 = Vector3.DOWN

@export_group("Movement variables")
@export var speed : float

@export var walk_speed : float = 2.0
@export var walk_anim_speed : float = 1.0
@export var run_speed : float = 3.0
@export var run_anim_speed : float = 1.0
@export var sneak_speed : float = 0.385
@export var sneak_anim_speed : float = 1.0

@export var jump_strength : float = 15.0
@export var gravity : float = 50.0

enum MoveState {IDLE, RUN, SPRINT, ROLL}
var move_state : MoveState = MoveState.IDLE
var sneaking : bool = false

var rolling_velocity : Vector3 = Vector3.ZERO

const ANIMATION_BLEND : float = 7.0

@onready var player_mesh : Node3D = $James
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var animator : AnimationTree = $AnimationTree
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var roll_timer : Timer = $RollTimer

func animate(delta):
	if is_on_floor():
		if velocity.length() > 0:
			# TODO: don't do this every update
			animator.set("parameters/ground_transition/transition_request", "Run")
			
			if sneaking:
				animator.set("parameters/ground_transition/transition_request", "Sneak")
			elif move_state == MoveState.SPRINT:
				var run_blend = lerp(animator.get("parameters/run_blend/blend_amount"), 1.0, delta * ANIMATION_BLEND)
				animator.set("parameters/run_blend/blend_amount", run_blend)
			elif move_state == MoveState.RUN:
				var run_blend = lerp(animator.get("parameters/run_blend/blend_amount"), 0.0, delta * ANIMATION_BLEND)
				animator.set("parameters/run_blend/blend_amount", run_blend)		
		else:
			if sneaking:
				# TODO: don't do this every update
				animator.set("parameters/ground_transition/transition_request", "Run")
			var run_blend = lerp(animator.get("parameters/run_blend/blend_amount"), -1.0, delta * ANIMATION_BLEND)
			# TODO: don't do this every update
			animator.set("parameters/run_blend/blend_amount", run_blend)
	else:
		# TODO: Jumping?
		#animator.set("parameters/ground_air_transition/transition_request", "air")
		pass
