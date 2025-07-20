extends CharacterBody3D

# Greg's movement speed
const SPEED = 3.0
const FLY_SPEED = 5.0
const FLIGHT_HEIGHT_OFFSET = 0.6 # How high Greg flies above his targets

# Collision avoidance settings
const AVOIDANCE_DISTANCE = 2.0 # How far ahead to check for obstacles
const AVOIDANCE_FORCE = 5.0 # How strong the avoidance steering is
const RAYCAST_COUNT = 9 # Number of raycasts in a fan pattern
const AVOIDANCE_ANGLE = 90 # The angle of the fan in degrees

# Greg's needs
const HUNGER_THRESHOLD = 50
const POOP_THRESHOLD = 30

# Animation names
const ANIM_IDLE = "greg_idle"
const ANIM_FLY = "greg_fly"

# States for Greg's behavior
enum State {
	GOING_TO_BIRDHOUSE,
	IDLE,
	GOING_TO_FOOD,
	FOLLOWING_PLAYER,
	EATING,
	POOPING_IN_TOILET,
	POOPING_ON_MAP,
	EXPLORING_WORLD
}

@export var birdhouse_area: Area3D
@export var poop_area: Area3D
@export var feed_area: Area3D
@export var player: CharacterBody3D
@export var poop_scene: PackedScene
@export var player_collision_layer: int = 1 # Which layer the player is on

@onready var animation_player: AnimationPlayer = $bird/AnimationPlayer
@onready var world_space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

var current_state = State.GOING_TO_BIRDHOUSE
var hunger = 0.0
var poop_urgency = 0.0
var idle_behavior_timer = 0.0
var target_position: Vector3
var desired_velocity: Vector3 = Vector3.ZERO
var avoidance_velocity: Vector3 = Vector3.ZERO
var poop_delay_timer: Timer
var has_started_pooping: bool = false
var current_fly_speed: float = 0.0

func _ready():
	motion_mode = MOTION_MODE_FLOATING
	# Start the idle behavior timer
	idle_behavior_timer = 3.0
	
	poop_delay_timer = Timer.new()
	add_child(poop_delay_timer)

func _physics_process(delta):
	# print_debug("Current state:", State.keys()[current_state])
	# Update needs over time
	hunger += delta
	poop_urgency += delta

	# 1. Hunger is the highest priority. If Greg is hungry, he must follow the player, unless there's food.
	if hunger > HUNGER_THRESHOLD and current_state != State.FOLLOWING_PLAYER and current_state != State.EATING:
		# If there's food, go eat it first.
		if _get_available_food():
			current_state = State.GOING_TO_FOOD
		else:
			# Start following the player
			current_state = State.FOLLOWING_PLAYER
			current_fly_speed = FLY_SPEED # Reset speed when starting to follow

	# 2. If not hungry, check for pooping needs.
	elif hunger <= HUNGER_THRESHOLD and poop_urgency > POOP_THRESHOLD and not _is_pooping_state(current_state):
		_initiate_pooping_sequence()

	# 3. If not hungry and not pooping, do rest of behavior
	match current_state:
		State.GOING_TO_BIRDHOUSE:
			_go_to_birdhouse_state(delta)
		State.IDLE:
			_idle_behavior_state(delta)
		State.GOING_TO_FOOD:
			_going_to_food_state(delta)
		State.FOLLOWING_PLAYER:
			_following_player_state(delta)
		State.EATING:
			_eating_state(delta)
		State.POOPING_IN_TOILET:
			_pooping_in_toilet_state(delta)
		State.POOPING_ON_MAP:
			_pooping_on_map_state(delta)

	# Apply collision avoidance
	_apply_collision_avoidance()

	# Orient Greg's model to face the direction of movement.
	if velocity.length_squared() > 0.01:
		$bird.transform.basis = Basis.looking_at(-velocity.normalized(), Vector3.UP)

	# Basic movement and animation
	move_and_slide()
	_update_animation()

func _is_pooping_state(state):
	return state == State.POOPING_IN_TOILET or state == State.POOPING_ON_MAP

func _apply_collision_avoidance():
	if desired_velocity.length_squared() < 0.01:
		velocity = desired_velocity
		return

	var forward_direction = desired_velocity.normalized()
	
	# Start rays from in front of Greg
	var ray_start_position = global_position + forward_direction * 0.5

	var query = PhysicsRayQueryParameters3D.create(ray_start_position, Vector3.ZERO)
	query.collision_mask = 0xFFFFFFFF & ~(1 << (player_collision_layer - 1))
	query.exclude = [self]

	# Check for obstacles and find the best clear direction
	var best_direction = forward_direction
	var max_dot_product = -1.0
	var clear_path_found = false

	for i in range(RAYCAST_COUNT):
		var angle = deg_to_rad(lerp(-AVOIDANCE_ANGLE, AVOIDANCE_ANGLE, float(i) / (RAYCAST_COUNT - 1)))
		var ray_direction = forward_direction.rotated(Vector3.UP, angle)
		
		query.to = ray_start_position + ray_direction * AVOIDANCE_DISTANCE
		var result = world_space.intersect_ray(query)

		if not result:
			# This path is clear. Check if it's the most forward-facing clear path.
			var dot_product = ray_direction.dot(forward_direction)
			if dot_product > max_dot_product:
				max_dot_product = dot_product
				best_direction = ray_direction
				clear_path_found = true

	# If no clear path was found at all, reverse direction
	if not clear_path_found:
		best_direction = - forward_direction

	# Smoothly steer towards the best direction
	var new_velocity = best_direction * desired_velocity.length()
	velocity = velocity.lerp(new_velocity, AVOIDANCE_FORCE * get_physics_process_delta_time())


func _update_animation():
	if velocity.length_squared() > 0.1:
		animation_player.play(ANIM_FLY)
	else:
		animation_player.play(ANIM_IDLE)

func _go_to_birdhouse_state(delta):
	# If we are already in the birdhouse, switch to idle behavior.
	if birdhouse_area.get_overlapping_bodies().has(self):
		desired_velocity = Vector3.ZERO
		current_state = State.IDLE
		return

	# Move towards the center of the birdhouse area.
	if birdhouse_area:
		var target_pos = birdhouse_area.global_position
		var direction = (target_pos - global_position).normalized()
		desired_velocity = direction * SPEED
	
	# If there's food in the feed area, go eat it
	if _get_available_food():
		current_state = State.GOING_TO_FOOD


func _idle_behavior_state(delta):
	# If there's food, go eat it first.
	if _get_available_food():
		current_state = State.GOING_TO_FOOD
		return

	idle_behavior_timer -= delta
	if not birdhouse_area.get_overlapping_bodies().has(self):
		current_state = State.GOING_TO_BIRDHOUSE
		idle_behavior_timer = 0
		return
	
	# Timer is up. First, check if we've left the birdhouse area.
	if idle_behavior_timer <= 0:
		# Get the collision shape to calculate random points within its bounds
		var shape_owner = birdhouse_area.get_children().filter(func(c): return c is CollisionShape3D)[0]
		if shape_owner and shape_owner.shape is BoxShape3D:
			var box_extents = shape_owner.shape.size / 2.0
			var area_center = birdhouse_area.global_position
			
			var random_number = randi() % 8 + 3 # rand float from 3 - 10
			# Generate a random point within the birdhouse area
			var random_offset = Vector3(
				randf_range(-box_extents.x, box_extents.x),
				0,
				randf_range(-box_extents.z, box_extents.z)
			)
			random_offset.y = FLIGHT_HEIGHT_OFFSET
			target_position = area_center + random_offset
			idle_behavior_timer = random_number
			return
		else:
			# Default behavior if no valid box shape is found
			desired_velocity = Vector3.ZERO
			idle_behavior_timer = 3.0
			return

	# If the timer is not up, continue moving towards the current target.
	if target_position != Vector3.ZERO:
		var direction = (target_position - global_position).normalized()
		desired_velocity = direction * SPEED
		
		# Stop moving if close enough to target
		if global_position.distance_to(target_position) < 0.5:
			desired_velocity = Vector3.ZERO
			target_position = Vector3.ZERO
	else:
		desired_velocity = Vector3.ZERO

func _going_to_food_state(delta):
	var food_item = _get_available_food()
	if food_item:
		var target_pos = food_item.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
		var direction = (target_pos - global_position).normalized()
		desired_velocity = direction * SPEED
		
		# If close enough, eat the food
		if global_position.distance_to(target_pos) < 1.5:
			food_item.queue_free()
			current_state = State.EATING
	else:
		# If food disappears while on the way, go back to the birdhouse
		current_state = State.GOING_TO_BIRDHOUSE


func _following_player_state(delta):
	if _get_available_food():
		current_state = State.GOING_TO_FOOD
		return
	
	# In this state, Greg follows the player
	if player:
		var target_pos = player.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
		var direction = (target_pos - global_position).normalized()
		
		# Increase speed over time
		current_fly_speed += delta / 2.0
		desired_velocity = direction * current_fly_speed
		
		# If Greg is close enough to the player, he "sits" on their head
		if global_position.distance_to(target_pos) < 1.5:
			global_position = player.global_position + Vector3(0, 1, 0) # Sit on head
			desired_velocity = Vector3.ZERO
			player.set_movement_restricted(true)
			
			# --- POOPING LOGIC WHILE FOLLOWING ---
			# If hungry, and he is close enough to the player, he will poop on the player, even if toilet is clean.
			if poop_urgency > 30:
				if not has_started_pooping:
					has_started_pooping = true
					# Poop immediately, then start a timer for subsequent poops
					_instance_poop_on_map()
					poop_delay_timer.wait_time = randf_range(2.0, 5.0)
					poop_delay_timer.timeout.connect(_keep_pooping_on_map)
					poop_delay_timer.start()
			else:
				# If the urge passes or the toilet is clean, stop the pooping timer
				has_started_pooping = false
				poop_delay_timer.stop()
				if poop_delay_timer.is_connected("timeout", _keep_pooping_on_map):
					poop_delay_timer.timeout.disconnect(_keep_pooping_on_map)

		else:
			# If we are flying towards the player, do not restrict movement
			player.set_movement_restricted(false)


func _eating_state(delta):
	# For now, just reset hunger and go back to birdhouse
	hunger = 0.0
	current_state = State.GOING_TO_BIRDHOUSE
	player.set_movement_restricted(false)

func _pooping_in_toilet_state(delta):
	# Move to the toilet
	if poop_area:
		var target_pos = poop_area.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
		var direction = (target_pos - global_position).normalized()
		desired_velocity = direction * SPEED
		
		# If close enough, start the pooping timer
		if global_position.distance_to(target_pos) < 1.0 and not has_started_pooping:
			has_started_pooping = true
			desired_velocity = Vector3.ZERO # Stop moving
			poop_delay_timer.wait_time = randf_range(2.0, 5.0)
			poop_delay_timer.timeout.connect(_finish_pooping_in_toilet, CONNECT_ONE_SHOT)
			poop_delay_timer.start()

func _finish_pooping_in_toilet():
	if poop_scene:
		var poop_instance = poop_scene.instantiate()
		get_parent().add_child(poop_instance)
		# Position the poop inside the toilet area
		poop_instance.global_position = poop_area.global_position + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	
	poop_urgency = 0.0
	current_state = State.GOING_TO_BIRDHOUSE

func _pooping_on_map_state(delta):
	# First, check if the toilet has been cleaned. If so, go home.
	if not _is_toilet_dirty():
		poop_urgency = 0.0
		current_state = State.GOING_TO_BIRDHOUSE
		poop_delay_timer.stop()
		if poop_delay_timer.is_connected("timeout", _keep_pooping_on_map):
			poop_delay_timer.timeout.disconnect(_keep_pooping_on_map)
		return

	# If the toilet is still dirty, continue pooping on the map
	if not has_started_pooping:
		has_started_pooping = true
		# Poop immediately, then start a timer for subsequent poops
		_instance_poop_on_map()
		poop_delay_timer.wait_time = randf_range(2.0, 5.0)
		poop_delay_timer.timeout.connect(_keep_pooping_on_map)
		poop_delay_timer.start()
	
	# Greg can just fly around randomly while in this state
	if target_position == Vector3.ZERO or global_position.distance_to(target_position) < 1.0:
		var random_offset = Vector3(randf_range(-5, 5), randf_range(0, 15), randf_range(-5, 5))
		target_position = global_position + random_offset

	if target_position != Vector3.ZERO:
		var direction = (target_position - global_position).normalized()
		desired_velocity = direction * SPEED
	else:
		desired_velocity = Vector3.ZERO

func _keep_pooping_on_map():
	_instance_poop_on_map()
	# The timer will restart automatically for the next interval
	poop_delay_timer.wait_time = randf_range(2.0, 5.0)

func _instance_poop_on_map():
	if poop_scene:
		var poop_instance = poop_scene.instantiate()
		get_parent().add_child(poop_instance)
		# Poop at a random offset from Greg
		var random_offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		poop_instance.global_position = global_position + random_offset

# Public function for the player to feed Greg
func feed():
	current_state = State.EATING

# Private function to check toilet status and decide where to poop
func _initiate_pooping_sequence():
	if _is_toilet_dirty():
		current_state = State.POOPING_ON_MAP
	else:
		current_state = State.POOPING_IN_TOILET
	
	target_position = Vector3.ZERO
	has_started_pooping = false

func _is_toilet_dirty():
	var poop_count = 0
	for body in poop_area.get_overlapping_bodies():
		if body.is_in_group("poop"):
			poop_count += 1
	return poop_count >= 3

func _get_available_food():
	if feed_area:
		for body in feed_area.get_overlapping_bodies():
			if body.is_in_group("food"):
				return body
	return null

func get_hunger():
	return hunger

func get_poop_urgency():
	return poop_urgency
