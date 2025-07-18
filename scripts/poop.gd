extends Area3D

# This signal can be used later to notify other parts of the game (like a score manager) that a poop has been cleaned.
signal cleaned

func _ready():
	# This connects the 'body_entered' signal of the Area3D to our custom function.
	# It will trigger whenever a PhysicsBody3D enters the poop's collision shape.
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# We check if the body that entered is the player.
	# For this to work, we'll need to add the player to a group called "player".
	if body.is_in_group("player"):
		# If it's the player, we emit the 'cleaned' signal and remove the poop from the game.
		emit_signal("cleaned")
		queue_free()
