extends Interactable
class_name Toilet

var is_using_toilet: bool = false
var player_using: Node = null
var original_position: Vector3

func _process(delta):
	if is_using_toilet and is_instance_valid(player_using):
		# Recover bladder over time while using the toilet
		if MotiveManager:
			var current_bladder = MotiveManager.get_motive("Bladder")
			MotiveManager.set_motive("Bladder", current_bladder + 15 * delta, 15 * delta)

func interact(player):
	if is_using_toilet:
		_stop_using()
	else:
		_start_using(player)

func _start_using(player):
	is_using_toilet = true
	player_using = player
	player.set_channeling(true)
	AudioInstancer.play_music(AudioInstancer.MusicTrack.ELEVATOR, true)

	var player_model = player.get_node("PlayerModel")
	if player_model:
		# Position the player model to sit on the toilet.
		# This may need adjustment depending on the model and toilet's origin.
		original_position = player_model.global_position
		player_model.rotation.x = 0 # Upright
		player_model.global_position = global_position + Vector3(0, 0.7, 0.7)
		
	player.animation_player.play(player.ANIM_IDLE_NAME)


func _stop_using():
	is_using_toilet = false
	AudioInstancer.restore_previous_track()
	if is_instance_valid(player_using):
		var player_model = player_using.get_node("PlayerModel")
		if player_model:
			player_model.global_position = original_position
		player_using.set_channeling(false)
	player_using = null
