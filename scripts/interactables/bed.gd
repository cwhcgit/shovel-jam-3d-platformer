extends Interactable
class_name Bed

var is_napping: bool = false
var player_napping: Node = null

func _process(delta):
	if is_napping and is_instance_valid(player_napping):
		# Recover energy over time while napping
		if MotiveManager:
			var current_energy = MotiveManager.get_motive("Energy")
			MotiveManager.set_motive("Energy", current_energy + 10 * delta)

func interact(player):
	if is_napping:
		_stop_napping()
	else:
		_start_napping(player)

func _start_napping(player):
	is_napping = true
	player_napping = player
	player.set_channeling(true)

func _stop_napping():
	is_napping = false
	if is_instance_valid(player_napping):
		player_napping.set_channeling(false)
	player_napping = null
