extends RigidBody3D

signal destroyed

const SCORE = 10
# In the event I want to score eating these (prob not)
# signal eaten

@export var explosion_scene: PackedScene
@export var explosion_color: Color = Color.ORANGE
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
				var current_hunger = MotiveManager.get_motive("Hunger")
				MotiveManager.set_motive("Hunger", current_hunger + 5, 5)
				
				var current_thirst = MotiveManager.get_motive("Thirst")
				MotiveManager.set_motive("Thirst", current_thirst + 5, 5)

				var current_bladder = MotiveManager.get_motive("Bladder")
				MotiveManager.set_motive("Bladder", current_bladder - 10, -10)
			break
			
	# Emit the signal before freeing the object
	emit_signal("destroyed")
	
	# Add score for doing action
	ScoreTimeManager.add_score(SCORE)
	
	# Remove the Carrot
	queue_free()
