extends Node

var poop_sound_cooldown := 3.0
var _is_poop_sound_ready := true
var _poop_sound_timer: Timer


# In your level script
func _ready():
	# Add to level group to be easily found
	add_to_group("level")

	# Poop sound timer
	_poop_sound_timer = Timer.new()
	_poop_sound_timer.wait_time = poop_sound_cooldown
	_poop_sound_timer.one_shot = true
	_poop_sound_timer.timeout.connect(_on_poop_sound_timer_timeout)
	add_child(_poop_sound_timer)

	# Play level music when level loads
	AudioInstancer.on_game_start()
	#var player = AudioStreamPlayer.new()
	#add_child(player)
	#player.stream = preload("res://assets/audio/music/LevelThemeCalm.wav")  # Use your actual path
	#player.play()
	#print("Trying to play audio...")

func can_play_poop_sound() -> bool:
	if _is_poop_sound_ready:
		_is_poop_sound_ready = false
		_poop_sound_timer.start()
		return true
	return false

func _on_poop_sound_timer_timeout():
	_is_poop_sound_ready = true
