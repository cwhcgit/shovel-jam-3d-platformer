extends Control

func _ready():
	print("Game Over Screen _ready() called.")
	$ColorRect/TryAgainButton.pressed.connect(_on_try_again_button_pressed)

func _on_try_again_button_pressed():
	print("Try Again button pressed!")
	ScoreTimeManager.reset_game_state()
	MotiveManager.reset_game_state()
	get_tree().paused = false
	get_tree().reload_current_scene()
