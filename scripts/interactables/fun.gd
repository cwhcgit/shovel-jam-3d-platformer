extends Interactable
class_name Fun

var is_having_fun: bool = false
var player_having_fun: Node = null
var original_position: Vector3
var original_rotation: Vector3
var on_sfx = preload("res://assets/audio/sound_effects/fun/tv-on-television-80399.mp3")
var off_sfx = preload("res://assets/audio/sound_effects/fun/tv-off-light-switch-off-86314.mp3")

func _process(delta):
	if is_having_fun and is_instance_valid(player_having_fun):
		# Recover fun over time
		if MotiveManager:
			var current_fun = MotiveManager.get_motive("Fun")
			MotiveManager.set_motive("Fun", current_fun + 15 * delta, 15 * delta)

func interact(player):
	if is_having_fun:
		_stop_having_fun()
	else:
		_start_having_fun(player)

func _start_having_fun(player):
	is_having_fun = true
	player_having_fun = player
	player.set_channeling(true)
	AudioInstancer.play_music(AudioInstancer.MusicTrack.ELEVATOR, true)
	AudioInstancer.play_sfx(on_sfx, 0.5)

	var player_model = player.get_node("PlayerModel")
	if player_model:
		# Store original state and position the player model at the object's origin
		original_position = player_model.global_position
		original_rotation = player_model.rotation
		player_model.global_position = global_position
		player_model.rotation = Vector3.ZERO
		
	player.animation_player.play(player.ANIM_IDLE_NAME)


func _stop_having_fun():
	is_having_fun = false
	AudioInstancer.restore_previous_track()
	AudioInstancer.play_sfx(off_sfx, 0.5)
	if is_instance_valid(player_having_fun):
		var player_model = player_having_fun.get_node("PlayerModel")
		if player_model:
			# Restore model's original position and rotation
			player_model.global_position = original_position
			player_model.rotation = original_rotation
		player_having_fun.set_channeling(false)
	player_having_fun = null
