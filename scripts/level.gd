extends Node

# In your level script
func _ready():
	# Play level music when level loads
	AudioInstancer.on_game_start()
	#var player = AudioStreamPlayer.new()
	#add_child(player)
	#player.stream = preload("res://assets/audio/music/LevelThemeCalm.wav")  # Use your actual path
	#player.play()
	#print("Trying to play audio...")
