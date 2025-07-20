extends Interactable
class_name Bed

var is_napping: bool = false
var player_napping: Node = null
var original_position: Vector3

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

	var player_model = player.get_node("Barbarian")
	original_position = player_model.global_position
	if player_model:
		# Player model faces +Z, with head towards +Y. To lie on back, rotate -90 degrees on X axis.
		player_model.rotation.x = deg_to_rad(-90)
		# Move model to bed's center and slightly above it to prevent clipping
		player_model.global_position = global_position + Vector3(0, 1, 0)
	player.animation_player.play(player.ANIM_IDLE_NAME)


func _stop_napping():
	is_napping = false
	if is_instance_valid(player_napping):
		var player_model = player_napping.get_node("Barbarian")
		if player_model:
			# Restore model's original rotation and local position
			player_model.global_position = original_position
			# player_model.rotation.x = 0
			# player_model.position = Vector3.ZERO
		player_napping.set_channeling(false)
	player_napping = null
