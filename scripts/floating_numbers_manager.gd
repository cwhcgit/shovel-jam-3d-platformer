# FloatingNumbersManager.gd - Autoload singleton
extends Node

var floating_number_scene = preload("res://scenes/ui/FloatingNumber.tscn")

func _ready():
	# Connect to the score manager's signal
	ScoreTimeManager.score_updated.connect(_on_score_updated)

var last_score = 0
var score_from_time = false

func _on_score_updated(new_score: float):
	var score_difference = new_score - last_score
	
	# Only show floating numbers for positive score changes that aren't from time
	if score_difference > 0 and not score_from_time:
		show_floating_number(int(score_difference))
	
	last_score = new_score
	
	# Reset the time flag after processing
	score_from_time = false

func mark_score_from_time():
	# Call this method before time-based score updates to suppress floating numbers
	score_from_time = true

func show_floating_number(score_value: int):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Warning: No player found in 'player' group")
		return
	
	# Get the camera from the player
	var camera = player.get_node("TwistPivot/PitchPivot/Camera3D")
	if not camera:
		print("Warning: Camera not found on player")
		return
	
	# Get the UI layer (assuming it's a CanvasLayer in the main scene)
	var ui_layer = get_tree().get_first_node_in_group("ui")
	if not ui_layer:
		# Fallback: try to find any CanvasLayer
		ui_layer = get_tree().get_nodes_in_group("ui")
		if ui_layer.is_empty():
			# Last fallback: create a temporary CanvasLayer
			ui_layer = CanvasLayer.new()
			get_tree().current_scene.add_child(ui_layer)
		else:
			ui_layer = ui_layer[0]
	
	# Create floating number instance
	var floating_number = floating_number_scene.instantiate()
	ui_layer.add_child(floating_number)
	
	# Position it above the player's head
	var player_head_position = player.global_position + Vector3(0, 2, 0)
	
	# Add some random offset so multiple numbers don't overlap
	var random_offset = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(0, 0.5),
		randf_range(-0.5, 0.5)
	)
	player_head_position += random_offset
	
	# Show the number
	floating_number.show_number(score_value, player_head_position, camera)
