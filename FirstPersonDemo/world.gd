extends Node3D

@onready var player_camera: Camera3D = $Player/Camera3D
@onready var mirror: Node = $Mirror

# The mirror object needs to know what camera it should render a projection for, since the player
# object is a sibling of the mirror object, we need to perform this initialization here in the
# world script.
func _ready():
	mirror.MainCam = player_camera
