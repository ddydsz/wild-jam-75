extends Node3D

signal chirp(pos: Vector3);

var scared = false;

func _ready() -> void:
	$Timer.start()

func _process(_delta: float) -> void:
	pass
	
func _on_timer_timeout():
	chirp.emit(self.position)
	
func set_scared(s: bool):
	if s:
		$Timer.stop();
	else:
		$Timer.start();
	scared = s;
