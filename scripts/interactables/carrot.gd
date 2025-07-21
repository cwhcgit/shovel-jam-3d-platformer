extends RigidBody3D

signal destroyed

const SCORE = 10
const CLEAN_SCORE = 100
# In the event I want to score eating these (prob not)
# signal eaten

@export var explosion_scene: PackedScene
@export var explosion_color: Color = Color.ORANGE
# @export var explosion_sounds: AudioStream
@export var clean_explosion_sound: AudioStream
var sfx_sheets = [
	"res://assets/audio/sound_effects/carrot/munch-1.mp3",
	"res://assets/audio/sound_effects/carrot/munch-2.mp3",
	"res://assets/audio/sound_effects/carrot/munch-3.mp3"
]

@onready var explosion_radius: Area3D = $ExplosionRadius

# This function is called by the player's attack
func take_damage(_damage):
	# Instance the explosion scene if it's set
	if explosion_scene:
		var explosion_instance = explosion_scene.instantiate()
		get_parent().add_child(explosion_instance)
		explosion_instance.global_position = global_position
		if explosion_instance.has_method("configure"):
			explosion_instance.configure(explosion_color)

	# Check for bodies in the explosion radius
	var bodies = explosion_radius.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if body.equipped_item is Mop:
				# Play clean carrot sound
				if clean_explosion_sound:
					AudioInstancer.play_sfx(clean_explosion_sound, 0.5)
					var current_hygiene = MotiveManager.get_motive("Hygiene")
					MotiveManager.set_motive("Hygiene", current_hygiene - 10, -10)
					# Add score for doing action
					ScoreTimeManager.add_score(CLEAN_SCORE)
				break
			if MotiveManager:
				var current_hunger = MotiveManager.get_motive("Hunger")
				MotiveManager.set_motive("Hunger", current_hunger + 5, 5)
				
				var current_thirst = MotiveManager.get_motive("Thirst")
				MotiveManager.set_motive("Thirst", current_thirst + 5, 5)

				var current_bladder = MotiveManager.get_motive("Bladder")
				MotiveManager.set_motive("Bladder", current_bladder - 10, -10)

				var random_index = randi() % sfx_sheets.size()
				AudioInstancer.play_sfx(load(sfx_sheets[random_index]), 0.5)
			break
			
	# Emit the signal before freeing the object
	emit_signal("destroyed")
	
	# Add score for doing action
	ScoreTimeManager.add_score(SCORE)
	
	# Remove the Carrot
	queue_free()
