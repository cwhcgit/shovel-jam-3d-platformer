extends Control

@onready var score_label = $ScoreLabel
@onready var time_label = $TimeLabel
@onready var game_over_screen = $"../GameOverScreen"

func _ready():
	ScoreTimeManager.score_updated.connect(on_score_updated)
	ScoreTimeManager.time_updated.connect(on_time_updated)
	ScoreTimeManager.game_over.connect(on_game_over)
	MotiveManager.game_over.connect(on_game_over)

	# Initialize labels with current values
	on_score_updated(ScoreTimeManager.get_score())
	on_time_updated(ScoreTimeManager.get_time_left())

	game_over_screen.hide()

func on_score_updated(new_score):
	score_label.text = "Score: " + str(int(new_score))

func on_time_updated(new_time):
	time_label.text = "Time: " + str(new_time)

func on_game_over():
	# Pause the game and show the game over screen
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	game_over_screen.show_screen()
