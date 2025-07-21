extends Node

# Audio Instancer for smooth music transitions
# Manages background music and sound effects for platformer game

# Music tracks enum for easy reference
enum MusicTrack {
	MAIN_THEME,
	MAIN_THEME_INTENSE,
	ELEVATOR
}

# Audio players for crossfading
@onready var music_player_1: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var music_player_2: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Current state
var current_track: MusicTrack = MusicTrack.MAIN_THEME
var previous_track: MusicTrack
var active_player: AudioStreamPlayer
var inactive_player: AudioStreamPlayer
var is_transitioning: bool = false
var is_music_locked: bool = false
var default_volume: float = 0.0  # 0 dB
var fade_duration: float = 2.0

# Music resources dictionary
var music_tracks: Dictionary = {}

signal music_changed(track: MusicTrack)
signal transition_completed()

func _ready():
	# This node should process even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Add audio players as children
	add_child(music_player_1)
	add_child(music_player_2)
	add_child(sfx_player)
	
	# Set initial active player
	active_player = music_player_1
	inactive_player = music_player_2
	
	# Configure audio players
	music_player_1.bus = "Music"
	music_player_2.bus = "Music"
	sfx_player.bus = "SFX"
	
	# Set initial volumes
	music_player_1.volume_db = default_volume
	music_player_2.volume_db = -80.0  # Start silent
	
	# Load music tracks (you'll need to assign these in the editor or code)
	load_music_tracks()
	
	# Start with main theme
	play_music(MusicTrack.MAIN_THEME, false)

func set_music_lock(locked: bool):
	is_music_locked = locked

func load_music_tracks():
	# Load your music files here - replace with actual paths
	music_tracks[MusicTrack.MAIN_THEME] = preload("res://assets/audio/music/LevelThemeCalm.wav")
	music_tracks[MusicTrack.MAIN_THEME_INTENSE] = preload("res://assets/audio/music/LevelThemeIntense.wav")
	music_tracks[MusicTrack.ELEVATOR] = preload("res://assets/audio/music/ElevatorMusic.wav")
	# music_tracks[MusicTrack.LEVEL_1] = preload("res://audio/music/level_1.ogg")
	# music_tracks[MusicTrack.BOSS_BATTLE] = preload("res://audio/music/boss_battle.ogg")
	# music_tracks[MusicTrack.UNDERGROUND] = preload("res://audio/music/underground.ogg")
	# music_tracks[MusicTrack.VICTORY] = preload("res://audio/music/victory.ogg")
	# music_tracks[MusicTrack.MENU] = preload("res://audio/music/menu.ogg")

func play_music(track: MusicTrack, smooth_transition: bool = true, force: bool = false):
	# If music is locked, do nothing unless forced
	if is_music_locked and not force:
		return

	# Don't restart the same track
	if track == current_track and active_player.playing:
		return
	
	# Check if track exists
	if not music_tracks.has(track):
		push_error("Music track not found: " + str(track))
		return
	
	previous_track = current_track

	var new_stream = music_tracks[track]
	
	if smooth_transition and active_player.playing:
		_smooth_transition_to(new_stream, track)
	else:
		_instant_transition_to(new_stream, track)

func _smooth_transition_to(new_stream: AudioStream, track: MusicTrack):
	if is_transitioning:
		return
	
	is_transitioning = true
	current_track = track
	
	# Set up the inactive player with new track
	inactive_player.stream = new_stream
	inactive_player.volume_db = -80.0
	inactive_player.play()
	
	# Create tween for crossfade that can run while paused
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to tween simultaneously
	
	# Crossfade between players
	tween.tween_property(active_player, "volume_db", -80.0, fade_duration)
	tween.tween_property(inactive_player, "volume_db", default_volume, fade_duration)
	
	# Wait for transition to complete
	await tween.finished
	_on_transition_complete()

func _instant_transition_to(new_stream: AudioStream, track: MusicTrack):
	active_player.stop()
	active_player.stream = new_stream
	active_player.volume_db = default_volume
	active_player.play()
	current_track = track
	music_changed.emit(track)

func _on_transition_complete():
	# Swap active/inactive players
	var temp = active_player
	active_player = inactive_player
	inactive_player = temp
	
	# Stop the now-inactive player
	inactive_player.stop()
	inactive_player.volume_db = -80.0
	
	is_transitioning = false
	music_changed.emit(current_track)
	transition_completed.emit()

func stop_music(fade_out: bool = true):
	if fade_out and active_player.playing:
		var tween = create_tween()
		tween.tween_property(active_player, "volume_db", -80.0, fade_duration / 2)
		await tween.finished
		active_player.stop()
	else:
		active_player.stop()

func pause_music():
	active_player.stream_paused = true

func resume_music():
	active_player.stream_paused = false

func set_music_volume(volume_db: float):
	default_volume = volume_db
	if not is_transitioning:
		active_player.volume_db = volume_db

func set_fade_duration(duration: float):
	fade_duration = maxf(duration, 0.1)  # Minimum fade time

# Sound effects methods
func play_sfx(sound: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer: 
	if sound == null:
		return null
	
	# Create a temporary audio player for this SFX
	var temp_player = AudioStreamPlayer.new()
	add_child(temp_player)
	temp_player.bus = "SFX"
	temp_player.stream = sound
	temp_player.volume_db = volume_db
	temp_player.play()
	
	# Remove player when finished
	temp_player.finished.connect(func(): temp_player.queue_free())
	return temp_player

func play_sfx_2d(sound: AudioStream, position: Vector2, volume_db: float = 0.0):
	if sound == null:
		return
	
	# Create a temporary 2D audio player for positional SFX
	var temp_player = AudioStreamPlayer2D.new()
	get_tree().current_scene.add_child(temp_player)
	temp_player.bus = "SFX"
	temp_player.stream = sound
	temp_player.volume_db = volume_db
	temp_player.global_position = position
	temp_player.play()
	
	# Remove player when finished
	temp_player.finished.connect(func(): temp_player.queue_free())

# Convenience methods for common game events
func on_game_start():
	print("Game started!, playing main theme")
	play_music(MusicTrack.MAIN_THEME)

func on_return_to_main():
	play_music(MusicTrack.MAIN_THEME)

func on_menu_open():
	pause_music()

func on_menu_close():
	resume_music()

func restore_previous_track():
	play_music(previous_track, false, true)

# Debug methods
func get_current_track_name() -> String:
	return MusicTrack.keys()[current_track]

func is_music_playing() -> bool:
	return active_player.playing