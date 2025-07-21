extends Node

signal score_updated(new_score)
signal time_updated(new_time)
signal game_over()

const TIME_LEFT_CONST = 180
var current_score = 0
var time_left = TIME_LEFT_CONST # seconds
var game_running = true
var _final_countdown_triggered = false

func _process(delta):
	if game_running:
		FloatingNumbersManager.mark_score_from_time()
		add_score(delta * 10)
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			game_running = false
			emit_signal("game_over")
		emit_signal("time_updated", int(time_left))

		# Check for final countdown
		if not _final_countdown_triggered and time_left <= 30.0:
			_final_countdown_triggered = true
			AudioInstancer.set_music_lock(true)
			AudioInstancer.play_music(AudioInstancer.MusicTrack.MAIN_THEME_INTENSE, true, true)

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
	_final_countdown_triggered = false
	AudioInstancer.set_music_lock(false)
	emit_signal("score_updated", current_score)
	emit_signal("time_updated", int(time_left))
