
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
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

	move_and_slide()
