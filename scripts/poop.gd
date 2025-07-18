extends RigidBody3D

# This signal can be used later to notify other parts of the game (like a score manager) that a poop has been cleaned.
signal cleaned

@export var explosion_scene: PackedScene
@export var explosion_color: Color = Color(0.36, 0.24, 0.16) # Default brown
@export var explosion_sound: AudioStream

@onready var explosion_radius: Area3D = $ExplosionRadius

# This function is called by the player's attack
func take_damage(_damage):
	# Instance the explosion scene if it's set
	if explosion_scene:
		var explosion_instance = explosion_scene.instantiate()
		get_parent().add_child(explosion_instance)
		explosion_instance.global_position = global_position
		if explosion_instance.has_method("configure_and_play"):
			explosion_instance.configure_and_play(explosion_color, explosion_sound)
	
	# Check for bodies in the explosion radius
	var bodies = explosion_radius.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if MotiveManager:
				var current_hygiene = MotiveManager.get_motive("Hygiene")
				MotiveManager.set_motive("Hygiene", current_hygiene - 25)
			break
			
	# Emit the cleaned signal and remove the poop
	emit_signal("cleaned")
	queue_free()
