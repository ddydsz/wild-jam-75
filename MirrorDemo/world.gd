extends Node3D

@onready var player_camera: Camera3D = $Player/CameraRod/MainCamera
@onready var mirror: Node = $Mirror
@onready var mirror2: Node = $Mirror2

# The mirror object needs to know what camera it should render a projection for, since the player
# object is a sibling of the mirror object, we need to perform this initialization here in the
# world script.
func _ready():
	mirror.MainCam = player_camera
	mirror2.MainCam = player_camera
