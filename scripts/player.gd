
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 2.0
const ANIM_JUMP_NAME = "Jump_Full_Short"
const ANIM_WALK_NAME = "Walking_A"
const ANIM_RUN_NAME = "Running_A"
const ANIM_INTERACT_NAME = "Interact"
const ANIM_IDLE_NAME = "Idle"

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var animation_player: AnimationPlayer = $Barbarian/AnimationPlayer

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left_move", "right_move", "up_move", "down_move")

	# Calculate direction based on camera orientation
	var cam_forward = spring_arm.global_transform.basis.z
	var cam_right = spring_arm.global_transform.basis.x
	
	var direction = (cam_forward * input_dir.y + cam_right * input_dir.x)
	direction.y = 0 # We only want to move on the XZ plane
	direction = direction.normalized()

	if direction:
		# Apply movement
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotate player to face movement direction
		if input_dir.y <= 0: # Prevent camera jitter when moving backwards
			transform.basis = transform.basis.slerp(Basis.looking_at(direction), delta * ROTATION_SPEED)
	else:
		# Apply deceleration
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	_update_animation()
	move_and_slide()

func _update_animation():
	var anim_to_play = ""
	if not is_on_floor():
		anim_to_play = ANIM_JUMP_NAME
	else:
		if Input.is_action_just_pressed("interact"):
			anim_to_play = ANIM_INTERACT_NAME
		elif velocity.length() > 0.1:
			anim_to_play = ANIM_RUN_NAME
		else:
			anim_to_play = ANIM_IDLE_NAME

	if animation_player.current_animation != anim_to_play:
		animation_player.play(anim_to_play)
