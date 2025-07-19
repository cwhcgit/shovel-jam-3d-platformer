extends Interactable
class_name Mop

@export var is_equipped: bool = false

@onready var glow_effect: Node3D = $GlowEffect

func _ready():
	# Ensure the glow is set correctly on game start
	set_glow_enabled(not is_equipped)

func interact(player):
	if is_equipped:
		drop(player)
	else:
		pickup(player)

func pickup(player):
	var holder = player.get_node("MopHolder")
	reparent(holder)
	
	# Position and align the mop using the markers
	var back_pos = holder.get_node("back_pos").global_position
	var front_pos = holder.get_node("front_pos").global_position
	look_at(front_pos, back_pos - front_pos)
	global_position = back_pos

	freeze = true
	is_equipped = true
	player.set_equipped_item(self)
	set_glow_enabled(false)

func drop(player):
	var scene_root = get_tree().root
	reparent(scene_root)
		
	freeze = false
	is_equipped = false
	
	if player:
		global_transform.origin = player.global_transform.origin + player.global_transform.basis.z * -1.5
		player.set_equipped_item(null)
	
	set_glow_enabled(true)

func set_glow_enabled(enabled: bool):
	if glow_effect:
		glow_effect.visible = enabled
		var particles = glow_effect.get_node("GPUParticles3D")
		if particles:
			particles.emitting = enabled
