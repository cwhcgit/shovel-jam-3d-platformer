extends RigidBody3D
class_name Interactable

func _ready():
	add_to_group("interactables")

func interact(player):
	# This method is meant to be overridden by child classes.
	pass
