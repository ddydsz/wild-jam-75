extends Control

var health : float = 100
var food : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_hit():
	self.health -= 10
	
	# turn screen red for a moment
	var tween = create_tween()
	tween.tween_method(_set_damage_overlay_opacity, 0.0, 1.0, 0.5)
	tween.tween_method(_set_damage_overlay_opacity, 1.0, 0.0, 0.5)
	
	$StatusBarMarginContainer/HealthBar.scale.x = health / 100.0

func _set_damage_overlay_opacity(opacity: float):
	$DamageTakenOverlay.material.set_shader_parameter("opacity", opacity)

func _on_player_got_food(amount: float) -> void:
	self.food += amount
	
	# flash screen for a moment
	var tween = create_tween()
	tween.tween_method(_set_food_overlay_opacity, 0.0, 1.0, 0.3)
	tween.tween_method(_set_food_overlay_opacity, 1.0, 0.0, 0.3)
	
	$StatusBarMarginContainer/FoodBar.scale.x = food / 100.0

func _set_food_overlay_opacity(opacity: float):
	$FoodEatenOverlay.material.set_shader_parameter("opacity", opacity)
	
func fade_to_black():
	var tween = create_tween()
	tween.tween_property($GameEndOverlay, "modulate:a", 1.0, 0.5)
