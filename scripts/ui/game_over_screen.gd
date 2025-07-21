extends Control

@onready var try_again_button = $ColorRect/TryAgainButton

func _ready():
	print("Game Over Screen _ready() called.")
	try_again_button.pressed.connect(_on_try_again_button_pressed)
	AudioInstancer.transition_completed.connect(_on_audio_transition_completed)

func show_screen():
	var music_playing = AudioInstancer.active_player.playing
	var playing_main_theme_intense = AudioInstancer.current_track == AudioInstancer.MusicTrack.MAIN_THEME
	if music_playing and playing_main_theme_intense:
		try_again_button.disabled = true
	show()

func _on_audio_transition_completed():
	if visible:
		try_again_button.disabled = false

func _on_try_again_button_pressed():
	print("Try Again button pressed!")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Reset game state managers first
	ScoreTimeManager.reset_game_state()
	MotiveManager.reset_game_state()
	
	_reset_music()
	
	# Unpause and reload the scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _reset_music():
	# Explicitly reset music to the main theme, ensuring the lock is off
	AudioInstancer.set_music_lock(false)
	AudioInstancer.play_music(AudioInstancer.MusicTrack.MAIN_THEME, false)