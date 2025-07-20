extends RigidBody3D

# This signal can be used later to notify other parts of the game (like a score manager) that a poop has been cleaned.
signal cleaned

@export var explosion_scene: PackedScene
@export var explosion_color: Color = Color(0.36, 0.24, 0.16) # Default brown
@export var explosion_sound: AudioStream
@export var hygiene_reduction_rate: float = 2.0 # How much hygiene is reduced per second

@onready var explosion_radius: Area3D = $ExplosionRadius

var player_in_range: bool = false
var player_node: Node3D = null

func _ready():
	# Connect the Area3D signals
	explosion_radius.body_entered.connect(_on_explosion_radius_body_entered)
	explosion_radius.body_exited.connect(_on_explosion_radius_body_exited)

func _process(delta):
	# Continuously reduce hygiene while player is in range
	if player_in_range and player_node and MotiveManager:
		print("Player in poop range - reducing hygiene")
		var current_hygiene = MotiveManager.get_motive("Hygiene")
		MotiveManager.set_motive("Hygiene", current_hygiene - delta * hygiene_reduction_rate)

func _on_player_process(delta):
	if MotiveManager:
		print("in poop range reducing hygeine")
		var current_hygiene = MotiveManager.get_motive("Hygiene")
		MotiveManager.set_motive("Hygiene", current_hygiene - delta * 2)

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
			if body.equipped_item is Mop:
				break
			if MotiveManager:
				var current_hygiene = MotiveManager.get_motive("Hygiene")
				MotiveManager.set_motive("Hygiene", current_hygiene - 25)
			break
			
	# Emit the cleaned signal and remove the poop
	emit_signal("cleaned")
	queue_free()

func _on_explosion_radius_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_node = body
		print("Player entered poop range")

func _on_explosion_radius_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player_node = null
		print("Player exited poop range")
