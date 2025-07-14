extends Node

signal score_updated(new_score)
signal time_updated(new_time)
signal game_over()

const TIME_LEFT_CONST = 3
var current_score = 0
var time_left = TIME_LEFT_CONST # seconds
var game_running = true

func _process(delta):
	if game_running:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			game_running = false
			emit_signal("game_over")
		emit_signal("time_updated", int(time_left))

func add_score(amount):
	current_score += amount
	emit_signal("score_updated", current_score)

func get_score():
	return current_score

func get_time_left():
	return time_left

func reset_game_state():
	current_score = 0
	time_left = TIME_LEFT_CONST
	game_running = true
	emit_signal("score_updated", current_score)
	emit_signal("time_updated", int(time_left))
