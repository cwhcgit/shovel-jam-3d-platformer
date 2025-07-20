extends CharacterBody3D

var speed = 5.0
const BASE_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

# not used anims
# const ANIM_WALK_NAME = "Walking_A"

# used anims
const ANIM_JUMP_NAME = "run" # alt
# const ANIM_RUN_NAME = "Running_A"
const ANIM_RUN_NAME = "run"
# const ANIM_INTERACT_NAME = "Interact"
const ANIM_INTERACT_NAME = "attack" # alt
# const ANIM_IDLE_NAME = "Idle"
const ANIM_IDLE_NAME = "idle"
const ANIM_DASH_NAME = "run" # alt
# const ANIM_ATTACK_NAME = "1H_Melee_Attack_Chop"
const ANIM_ATTACK_NAME = "attack"

# Other consts
const MAX_JUMPS = 2
const WALL_JUMP_FORCE = 7.0
const WALL_JUMP_COOLDOWN_TIME = 0.3
const DASH_SPEED = 25.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN_TIME = 1.0
const ATTACK_COOLDOWN_TIME = 0.8

# State and variables
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jump_count = 0
var wall_jump_cooldown = 0.0
var attack_cooldown = 0.0
enum DashState {READY, DASHING, COOLDOWN}
var dash_state = DashState.READY
var movement_restricted: bool = false
var is_channeling: bool = false
var equipped_item: Node = null
var nearby_interactable: Node = null

@onready var animation_player: AnimationPlayer = $PlayerModel/AnimationPlayer
@onready var twist_pivot: Node3D = $TwistPivot
@onready var pitch_pivot: Node3D = $TwistPivot/PitchPivot
@onready var camera: Camera3D = $TwistPivot/PitchPivot/Camera3D
@onready var attack_shape_cast: ShapeCast3D = $AttackShapeCast
@onready var interactable_detector: Area3D = $InteractableDetector
var camera_default_distance: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Store the camera's initial Z position as its default resting distance.
	camera_default_distance = camera.position.z
	interactable_detector.body_entered.connect(_on_interactable_detector_body_entered)
	interactable_detector.body_exited.connect(_on_interactable_detector_body_exited)

func _on_interactable_detector_body_entered(body):
	if body.is_in_group("interactables"):
		nearby_interactable = body

func _on_interactable_detector_body_exited(body):
	if body == nearby_interactable:
		nearby_interactable = null

func set_equipped_item(item):
	equipped_item = item

func set_channeling(channeling: bool):
	is_channeling = channeling
	if is_channeling:
		velocity = Vector3.ZERO


func _unhandled_input(event):
	if is_channeling:
		return
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			# Store the original rotation in case we need to revert it.
			var original_rotation = pitch_pivot.rotation.x
			
			# Apply the rotation from mouse input.
			twist_pivot.rotate_y(-event.relative.x * SENSITIVITY)
			pitch_pivot.rotate_x(-event.relative.y * SENSITIVITY)
			
			# Clamp the angle to a reasonable range.
			pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))

			# Clamp the rotation of the camera such that it's never lower than the player's feet
			if camera.global_position.y < global_position.y:
				pitch_pivot.rotation.x = original_rotation

func _physics_process(delta):
	_handle_gravity(delta)
	if wall_jump_cooldown > 0:
		wall_jump_cooldown -= delta
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# The interact action is always available to start or cancel channeling
	if Input.is_action_just_pressed("interact"):
		_handle_interact()

	if is_channeling:
		velocity = Vector3.ZERO
	else:
		# Handle other user input for actions only when not channeling
		if not movement_restricted:
			if Input.is_action_just_pressed("jump"):
				_handle_jump()
			if Input.is_action_just_pressed("dash") and dash_state == DashState.READY:
				_perform_dash()
		if Input.is_action_just_pressed("attack") and attack_cooldown <= 0:
			_handle_attack()

		# Handle movement if not dashing
		if dash_state != DashState.DASHING:
			_handle_movement(delta)

	# Apply movement
	move_and_slide()
	
	# After moving, check for and resolve camera collisions.
	_update_camera_collision(delta)
	
	# Update animations
	_update_animation()

func _update_camera_collision(delta):
	var space_state = get_world_3d().direct_space_state
	var cam_global_pos = camera.global_position
	var pivot_global_pos = pitch_pivot.global_position

	var query = PhysicsRayQueryParameters3D.create(pivot_global_pos, cam_global_pos, collision_mask, [self])
	var result = space_state.intersect_ray(query)

	# Always set camera at default distance, other collision objects that's not the player will be 'seen through'
	if not result:
		# No collision. Only lerp back if the camera is not already at its default distance.
		if not is_equal_approx(camera.position.z, camera_default_distance):
			camera.position.z = lerp(camera.position.z, camera_default_distance, delta * 8.0)

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		jump_count = 0

func _handle_jump():
	var wall_normal = _get_wall_normal()
	if wall_normal != Vector3.ZERO and not is_on_floor():
		velocity = velocity.bounce(wall_normal)
		velocity += wall_normal * WALL_JUMP_FORCE
		velocity.y = JUMP_VELOCITY
		wall_jump_cooldown = WALL_JUMP_COOLDOWN_TIME
		jump_count = 1
	elif jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

func _handle_movement(_delta):
	var input_dir = Input.get_vector("left_move", "right_move", "up_move", "down_move")
	
	# Calculate the intended direction in world space based on camera orientation.
	var move_direction = (twist_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if move_direction.length() > 0.01: # Only handle rotations when there's input
		# Move direction is the reverse of input direction due to model facing
		velocity.x = - move_direction.x * speed
		velocity.z = - move_direction.z * speed

		# Rotate the model to face the true movement direction (-move_direction), 
		# necessary because velocity direction is now reversed, and unusable with facing direction
		# Because the model's front is +Z, we need its -Z to point toward the opposite of our goal.
		# Use Basis.looking_at() to prevent the model from tilting up or down.
		$PlayerModel.transform.basis = Basis.looking_at(move_direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func _handle_attack():
	attack_cooldown = ATTACK_COOLDOWN_TIME
	animation_player.play(ANIM_ATTACK_NAME)
	
	# Force the shape cast to update its collision information
	attack_shape_cast.force_shapecast_update()
	
	# Check for collisions
	for i in range(attack_shape_cast.get_collision_count()):
		var collider = attack_shape_cast.get_collider(i)
		if collider and collider.has_method("take_damage"):
			# Assuming the enemy has a 'take_damage' method
			collider.call("take_damage", 10) # Deal 10 damage

func _handle_interact():
	if equipped_item:
		animation_player.play(ANIM_INTERACT_NAME)
		equipped_item.call("drop", self)
	elif nearby_interactable:
		animation_player.play(ANIM_INTERACT_NAME)
		nearby_interactable.call("interact", self)

func _get_wall_normal():
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision.get_normal().y < 0.1:
				return collision.get_normal()
	return Vector3.ZERO

func _perform_dash():
	dash_state = DashState.DASHING
	var dash_direction = - twist_pivot.global_transform.basis.z.normalized()
	if velocity.length() > 0.1:
		dash_direction = velocity.normalized()
	
	velocity = dash_direction * DASH_SPEED
	
	await get_tree().create_timer(DASH_DURATION).timeout
	dash_state = DashState.COOLDOWN
	
	await get_tree().create_timer(DASH_COOLDOWN_TIME).timeout
	dash_state = DashState.READY

func _update_animation():
	var anim_to_play = ""
	
	if animation_player.current_animation == ANIM_INTERACT_NAME and animation_player.is_playing():
		return

	if attack_cooldown > 0:
		anim_to_play = ANIM_ATTACK_NAME
	elif not is_on_floor():
		anim_to_play = ANIM_JUMP_NAME
	else:
		if dash_state == DashState.DASHING:
			anim_to_play = ANIM_DASH_NAME
		elif velocity.length_squared() > 0.1:
			anim_to_play = ANIM_RUN_NAME
		else:
			anim_to_play = ANIM_IDLE_NAME

	if animation_player.current_animation != anim_to_play:
		animation_player.play(anim_to_play)

func set_movement_restricted(is_restricted: bool):
	movement_restricted = is_restricted
	if is_restricted:
		speed = BASE_SPEED * 0.75
	else:
		speed = BASE_SPEED
