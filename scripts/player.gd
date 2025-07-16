extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 10.0 # Increased for snappier feel
const IDLE_ROTATION_SPEED = 5.0 # Slower rotation when not moving
const ANIM_JUMP_NAME = "Jump_Full_Short"
const ANIM_WALK_NAME = "Walking_A"
const ANIM_RUN_NAME = "Running_A"
const ANIM_INTERACT_NAME = "Interact"
const ANIM_IDLE_NAME = "Idle"
const ANIM_DASH_NAME = "Dodge_Forward"

var jump_count = 0
const MAX_JUMPS = 2
const WALL_JUMP_FORCE = 7.0
var wall_jump_cooldown = 0.0
const WALL_JUMP_COOLDOWN_TIME = 0.3

const DASH_SPEED = 25.0
var dash_duration = 0.2
var dash_cooldown = 1.0
enum { DASH_READY, DASHING, DASH_COOLDOWN }
var dash_state = DASH_READY

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var animation_player: AnimationPlayer = $Barbarian/AnimationPlayer

func _physics_process(delta):
	_handle_gravity(delta)
	_handle_cooldowns(delta)
	_handle_input()

	if dash_state == DASHING:
		move_and_slide()
		return

	if wall_jump_cooldown <= 0:
		_handle_movement()

	_update_rotation(delta)
	_update_animation()
	move_and_slide()

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		jump_count = 0

func _handle_cooldowns(delta):
	if wall_jump_cooldown > 0:
		wall_jump_cooldown -= delta

func _handle_input():
	if Input.is_action_just_pressed("jump"):
		var wall_normal = _get_wall_normal()
		if wall_normal != Vector3.ZERO and not is_on_floor():
			_perform_wall_jump(wall_normal)
		elif jump_count < MAX_JUMPS:
			_perform_regular_jump()
	
	if Input.is_action_just_pressed("dash") and dash_state == DASH_READY:
		dash()

func _perform_wall_jump(wall_normal):
	velocity = velocity.bounce(wall_normal)
	velocity += wall_normal * WALL_JUMP_FORCE
	velocity.y = JUMP_VELOCITY
	wall_jump_cooldown = WALL_JUMP_COOLDOWN_TIME
	jump_count = 1 # Reset jump count to allow a double jump after the wall jump

func _perform_regular_jump():
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func _handle_movement():
	var input_dir = Input.get_vector("left_move", "right_move", "up_move", "down_move")
	var cam_forward = spring_arm.global_transform.basis.z
	var cam_right = spring_arm.global_transform.basis.x
	var direction = (cam_forward * input_dir.y + cam_right * input_dir.x)
	direction.y = 0
	direction = direction.normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _update_rotation(delta):
	var direction = Vector3.ZERO
	var input_dir = Input.get_vector("left_move", "right_move", "up_move", "down_move")
	var current_rotation_speed = ROTATION_SPEED # Default to fast rotation

	if wall_jump_cooldown > 0:
		direction = velocity
		direction.y = 0
	else:
		var cam_forward = spring_arm.global_transform.basis.z
		var cam_right = spring_arm.global_transform.basis.x
		direction = (cam_forward * input_dir.y + cam_right * input_dir.x)
		direction.y = 0
		# If only rotating (A/D pressed, but no W/S), use idle speed
		if abs(input_dir.y) < 0.1 and abs(input_dir.x) > 0.1:
			current_rotation_speed = IDLE_ROTATION_SPEED

	if direction.length() > 0.1: # Only rotate if there's a direction to look at
		var target_basis = Basis.looking_at(direction.normalized())
		transform.basis = transform.basis.slerp(target_basis, delta * current_rotation_speed)

func _get_wall_normal():
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision.get_normal().y < 0.1:
				print("Wall detected! Normal: ", collision.get_normal())
				return collision.get_normal()
	return Vector3.ZERO

func dash():
	dash_state = DASHING
	var dash_direction = -transform.basis.z.normalized()
	if velocity.length() > 0:
		dash_direction = velocity.normalized()
	velocity = dash_direction * DASH_SPEED
	await get_tree().create_timer(dash_duration).timeout
	dash_state = DASH_COOLDOWN
	await get_tree().create_timer(dash_cooldown).timeout
	dash_state = DASH_READY

func _update_animation():
	var anim_to_play = ""
	if not is_on_floor():
		anim_to_play = ANIM_JUMP_NAME
	else:
		if Input.is_action_just_pressed("interact"):
			anim_to_play = ANIM_INTERACT_NAME
		elif dash_state == DASHING:
			anim_to_play = ANIM_DASH_NAME
		elif velocity.length() > 0.1:
			anim_to_play = ANIM_RUN_NAME
		else:
			anim_to_play = ANIM_IDLE_NAME

	if animation_player.current_animation != anim_to_play:
		animation_player.play(anim_to_play)
