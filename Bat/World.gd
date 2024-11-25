extends Node3D

@export_file("*.tscn") var main_menu_scene : String

var game_time = 0.0;
var pulse_sources: Array[Vector4];
var pulse_sources_dirty = true;
var pulse_sources_tex: ImageTexture = ImageTexture.new()
var daylightcon = 0
var is_outside = 0

var hints_shown: Array[String] = []

var debug_enabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	_show_hint("Left click to chirp and see your surroundings", 2.0)
	_show_hint("Use WASD to fly around", 7.0)
	_show_hint("Space and control to fly up and down", 12.0)
	
func _set_hint_label_text(text: String):
	$UI/Hints/HintLabel.text = text

func _show_hint(text: String, delay: float = 0.0):
	if !hints_shown.has(text):
		hints_shown.append(text)
		var hint_tween = create_tween()
		hint_tween.tween_interval(delay)
		hint_tween.tween_callback(_set_hint_label_text.bind(text))
		hint_tween.tween_property($UI/Hints/HintLabel, "modulate:a", 1.0, 0.5)
		hint_tween.tween_interval(3.0)
		hint_tween.tween_property($UI/Hints/HintLabel, "modulate:a", 0.0, 0.5)
	
func _on_daylight_timer_timeout() -> void:
	if daylightcon == 2:
		$DaylightTimer.stop()
		if is_outside:
			_game_over_screen()
		else:
			_game_won_screen()
	if daylightcon == 1:
		daylightcon = 2
		$DaylightTimer.start(40)
		_show_hint("Sunrise is coming soon... Better head back.")
	if daylightcon == 0:
		daylightcon = 1
		#wentoutside = 1
		$HintCollisionShapes/GoOutsideHint.process_mode = Node.PROCESS_MODE_INHERIT
		$DaylightTimer.start(40)
		_show_hint("It's starting to get brighter out...")


func _on_player_hint_enemies() -> void:
	#$HintCollisionShapes/EnemiesHint.process_mode = Node.PROCESS_MODE_DISABLED
	_show_hint("Getting too close to mushrooms and spiders will hurt you")

func _on_player_hint_go_outside() -> void:
	#$HintCollisionShapes/GoOutsideHint.process_mode = Node.PROCESS_MODE_DISABLED
	if !$DaylightTimer.is_stopped():
		$DaylightTimer.stop()
		_game_won_screen()
	else:
		_show_hint("Find your way out of the cave")

func _on_player_hint_inside() -> void:
	is_outside = false

func _on_player_hint_outside() -> void:
	#$HintCollisionShapes/OutsideHint.process_mode = Node.PROCESS_MODE_DISABLED
	_show_hint("Hunt some critters before sunrise")
	is_outside = true
	if $DaylightTimer.is_stopped():
		$DaylightTimer.start(30)
	
func _game_over_screen(what: String = "sunlight"):
	var tween = create_tween()
	tween.tween_callback($UI.fade_to_black)
	tween.tween_interval(1.0)
	tween.tween_callback(_show_hint.bind("You died. The "+what+" killed you."))
	tween.tween_interval(4.0)
	tween.tween_callback(_show_hint.bind("This is what it is like to be a bat."))
	tween.tween_interval(4.0)
	tween.tween_callback(SceneLoader.load_scene.bind(main_menu_scene))
	
func _game_won_screen():
	var tween = create_tween()
	tween.tween_callback($UI.fade_to_black)
	tween.tween_interval(1.0)
	tween.tween_callback(_show_hint.bind("You made it back to your cave. Good job."))
	tween.tween_interval(4.0)
	tween.tween_callback(_show_hint.bind("This is what it is like to be a bat."))
	tween.tween_interval(4.0)
	tween.tween_callback(SceneLoader.load_scene.bind(main_menu_scene))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Input.is_action_just_pressed("teleport_starting_point"):
		$Player.transform = $StartingPoint.transform
	if Input.is_action_just_pressed("teleport_outside"):
		$Player.transform = $Outside.transform
	
	if Input.is_action_just_pressed("debug_mode_toggle"):
		debug_enabled = !debug_enabled
		RenderingServer.global_shader_parameter_set("debug_enabled", debug_enabled)

	pulse_process(delta)

func pulse_process(delta):
	game_time += delta;
	RenderingServer.global_shader_parameter_set("game_time", game_time);

	# create pulses at static position
	#if game_time > chirp_pulse_last + 8:
		#chirp_pulse_last = game_time;
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.2));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.4));
		#pulse_sources.push_back(Vector4(-4.0, 0.0, -4.0, game_time + 0.6));
		#dirty = true;

	if pulse_sources_dirty:
		# pulse update logic
		RenderingServer.global_shader_parameter_set("pulse_sources", make_pulse_sources(pulse_sources));
		pulse_sources_dirty = false;

func add_pulse(src: Vector3, start_time: float):
	pulse_sources.push_back(Vector4(src.x, src.y, src.z, start_time));
	pulse_sources_dirty = true;

func rm_old_pulses():
	var i = 0;
	while i < len(pulse_sources):
		if game_time - pulse_sources[i].w > 10:
			pulse_sources_dirty = true;
			pulse_sources.remove_at(i);
		else:
			i += 1;

func make_pulse_sources(sources: Array[Vector4]):
	# we have to have at least one pixel or godot errors at dev.texture_create
	var data = PackedFloat32Array([0.0, 0.0, 0.0, 0.0]);
	for source in sources:
		data.push_back(source.x);
		data.push_back(source.y);
		data.push_back(source.z);
		data.push_back(source.w);
	var img = Image.create_from_data(sources.size()+1, 1, false, Image.FORMAT_RGBAF, data.to_byte_array())
	pulse_sources_tex.set_image(img)
	return pulse_sources_tex

func _on_chirp(pos: Vector3) -> void:
	add_pulse(pos, game_time)


func _on_ui_unalived() -> void:
	_game_over_screen("bad critters")
