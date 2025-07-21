extends Interactable
class_name Bed

var is_napping: bool = false
var player_napping: Node = null
var original_position: Vector3
var sfx_timer: Timer

var sfx_sheets = [
	preload("res://assets/audio/sound_effects/bed/snore_part_1.mp3"),
	preload("res://assets/audio/sound_effects/bed/snore_part_2.mp3"),
	preload("res://assets/audio/sound_effects/bed/snore_part_3.mp3"),
	preload("res://assets/audio/sound_effects/bed/snore_part_4.mp3"),
	preload("res://assets/audio/sound_effects/bed/snore_part_5.mp3"),
	preload("res://assets/audio/sound_effects/bed/snore_part_6.mp3"),
]

func _process(delta):
	if is_napping and is_instance_valid(player_napping):
		# Recover energy over time while napping
		if MotiveManager:
			var current_energy = MotiveManager.get_motive("Energy")
			MotiveManager.set_motive("Energy", current_energy + 10 * delta, 10 * delta)

func interact(player):
	if is_napping:
		_stop_napping()
	else:
		_start_napping(player)

func _start_napping(player):
	is_napping = true
	player_napping = player
	player.set_channeling(true)
	AudioInstancer.play_music(AudioInstancer.MusicTrack.ELEVATOR, true)

	sfx_timer = Timer.new()
	sfx_timer.wait_time = 2.5
	sfx_timer.one_shot = false
	sfx_timer.timeout.connect(_on_SfxTimer_timeout)
	add_child(sfx_timer)
	sfx_timer.start()
	_on_SfxTimer_timeout() # Play a sound immediately.

	var player_model = player.get_node("PlayerModel")
	original_position = player_model.global_position
	if player_model:
		# Player model faces +Z, with head towards +Y. To lie on back, rotate -90 degrees on X axis.
		player_model.rotation.x = deg_to_rad(-90)
		# Move model to bed's center and slightly above it to prevent clipping
		player_model.global_position = global_position + Vector3(0, 1, 0)
	player.animation_player.play(player.ANIM_IDLE_NAME)


func _stop_napping():
	is_napping = false
	AudioInstancer.restore_previous_track()
	if is_instance_valid(player_napping):
		var player_model = player_napping.get_node("PlayerModel")
		if player_model:
			# Restore model's original rotation and local position
			player_model.global_position = original_position
			# player_model.rotation.x = 0
			# player_model.position = Vector3.ZERO
		player_napping.set_channeling(false)
	player_napping = null
	if sfx_timer:
		sfx_timer.stop()
		sfx_timer.queue_free()
		sfx_timer = null

func _on_SfxTimer_timeout():
	if sfx_sheets.size() > 0:
		var random_index = randi() % sfx_sheets.size()
		AudioInstancer.play_sfx(sfx_sheets[random_index], 0.5)
