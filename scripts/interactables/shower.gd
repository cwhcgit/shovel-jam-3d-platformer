extends Interactable
class_name Shower

var is_showering: bool = false
var player_showering: Node = null
var original_position: Vector3
var original_rotation: Vector3

func _process(delta):
	if is_showering and is_instance_valid(player_showering):
		# Recover hygiene over time while showering
		if MotiveManager:
			var current_hygiene = MotiveManager.get_motive("Hygiene")
			MotiveManager.set_motive("Hygiene", current_hygiene + 15 * delta, 15 * delta)

func interact(player):
	if is_showering:
		_stop_showering()
	else:
		_start_showering(player)

func _start_showering(player):
	is_showering = true
	player_showering = player
	player.set_channeling(true)

	var player_model = player.get_node("PlayerModel")
	if player_model:
		# Position the player model at the shower's origin.
		original_position = player_model.global_position
		original_rotation = player_model.rotation
		player_model.global_position = global_position
		player_model.rotation = Vector3.ZERO # Stand upright, facing forward
		
	player.animation_player.play(player.ANIM_IDLE_NAME)


func _stop_showering():
	is_showering = false
	if is_instance_valid(player_showering):
		var player_model = player_showering.get_node("PlayerModel")
		if player_model:
			player_model.global_position = original_position
			player_model.rotation = original_rotation
		player_showering.set_channeling(false)
	player_showering = null
