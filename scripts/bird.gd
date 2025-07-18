extends CharacterBody3D

# Greg's movement speed
const SPEED = 3.0
const FLY_SPEED = 5.0
const FLIGHT_HEIGHT_OFFSET = 0.6 # How high Greg flies above his targets

# Collision avoidance settings
const AVOIDANCE_DISTANCE = 2.0 # How far ahead to check for obstacles
const AVOIDANCE_FORCE = 1.5 # How strong the avoidance steering is
const RAYCAST_COUNT = 5 # Number of raycasts in a fan pattern

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

# Public variables that can be set in the editor
@export var birdhouse_area: Area3D
@export var poop_area: Area3D
@export var feed_area: Area3D
@export var player: CharacterBody3D
@export var poop_scene: PackedScene
@export var player_collision_layer: int = 1 # Which layer the player is on

@onready var animation_player: AnimationPlayer = $bird/AnimationPlayer
@onready var world_space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

# Greg's internal state
var current_state = State.GOING_TO_BIRDHOUSE
var hunger = 0.0
var poop_urgency = 0.0
var idle_behavior_timer = 0.0
var target_position: Vector3
var desired_velocity: Vector3 = Vector3.ZERO
var avoidance_velocity: Vector3 = Vector3.ZERO
var poop_delay_timer: Timer
var has_started_pooping: bool = false


func _ready():
	motion_mode = MOTION_MODE_FLOATING
	# Start the idle behavior timer
	idle_behavior_timer = 3.0
	
	poop_delay_timer = Timer.new()
	add_child(poop_delay_timer)

func _physics_process(delta):
	# Update needs over time
	hunger += delta
	poop_urgency += delta

	# State machine logic
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

	# Check if Greg needs to poop
	if poop_urgency > 1 and current_state != State.POOPING_IN_TOILET and current_state != State.POOPING_ON_MAP:
		_initiate_pooping_sequence()

	# Apply collision avoidance
	_apply_collision_avoidance()

	# Orient the bird model to face the direction of movement.
	if velocity.length_squared() > 0.01:
		# The model's front is +Z, but looking_at points -Z.
		# So, we point the back of the model (-Z) to the opposite of the velocity.
		$bird.transform.basis = Basis.looking_at(-velocity.normalized(), Vector3.UP)

	# Basic movement and animation
	move_and_slide()
	_update_animation()

func _apply_collision_avoidance():
	avoidance_velocity = Vector3.ZERO
	
	# Only apply avoidance if we're moving
	if desired_velocity.length_squared() < 0.01:
		velocity = desired_velocity
		return
	
	# Create multiple raycasts in a fan pattern
	var forward = desired_velocity.normalized()
	var right = forward.cross(Vector3.UP).normalized()
	
	var obstacles_detected = false
	var avoidance_direction = Vector3.ZERO
	
	for i in range(RAYCAST_COUNT):
		# Create rays in a fan pattern
		var angle = deg_to_rad(lerp(-45.0, 45.0, float(i) / float(RAYCAST_COUNT - 1)))
		var ray_direction = forward.rotated(Vector3.UP, angle)
		
		var ray_start = global_position
		var ray_end = global_position + ray_direction * AVOIDANCE_DISTANCE
		
		# Create the raycast query
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		# Exclude the player collision layer
		query.collision_mask = 0xFFFFFFFF & ~(1 << (player_collision_layer - 1))
		query.exclude = [self] # Don't collide with self
		
		var result = world_space.intersect_ray(query)
		
		if result:
			obstacles_detected = true
			# Calculate avoidance direction (perpendicular to the obstacle)
			var obstacle_normal = result.normal
			var avoidance_force = (1.0 - (ray_start.distance_to(result.position) / AVOIDANCE_DISTANCE))
			avoidance_direction += obstacle_normal * avoidance_force
	
	if obstacles_detected:
		# Apply avoidance steering
		avoidance_velocity = avoidance_direction.normalized() * AVOIDANCE_FORCE
		# Combine desired velocity with avoidance
		velocity = (desired_velocity + avoidance_velocity).normalized() * desired_velocity.length()
	else:
		velocity = desired_velocity

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
	if feed_area and not feed_area.get_overlapping_bodies().is_empty():
		current_state = State.GOING_TO_FOOD
	# If Greg gets too hungry, he starts following the player
	elif hunger > 50:
		current_state = State.FOLLOWING_PLAYER

func _idle_behavior_state(delta):
	idle_behavior_timer -= delta
	if not birdhouse_area.get_overlapping_bodies().has(self):
		current_state = State.GOING_TO_BIRDHOUSE
		idle_behavior_timer = 0
		return
	
	if idle_behavior_timer <= 0:
		# Timer is up. First, check if we've left the birdhouse area.
		
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
	if feed_area:
		var target_pos = feed_area.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
		var direction = (target_pos - global_position).normalized()
		desired_velocity = direction * SPEED
		
		# If close enough, eat the food
		if global_position.distance_to(target_pos) < 1.5:
			# Consume the food (for now, just destroy the first food item found)
			var food = feed_area.get_overlapping_bodies()[0]
			food.queue_free()
			current_state = State.EATING

func _following_player_state(delta):
	# In this state, Greg follows the player
	if player:
		var target_pos = player.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
		var direction = (target_pos - global_position).normalized()
		desired_velocity = direction * SPEED
		
		# If Greg is close enough to the player, he "sits" on their head
		if global_position.distance_to(target_pos) < 1.5:
			global_position = player.global_position + Vector3(0, 1, 0) # Sit on head
			desired_velocity = Vector3.ZERO

func _eating_state(delta):
	# For now, just reset hunger and go back to birdhouse
	hunger = 0.0
	current_state = State.GOING_TO_BIRDHOUSE

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
	# First, check if the toilet has been cleaned
	var poop_count = 0
	for body in poop_area.get_overlapping_bodies():
		if body.is_in_group("poop"):
			poop_count += 1
	
	if poop_count == 0:
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
	
	# The bird can just fly around randomly while in this state
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
		# Poop at a random offset from the bird
		var random_offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		poop_instance.global_position = global_position + random_offset

# Public function for the player to feed Greg
func feed():
	current_state = State.EATING

# Private function to check toilet status and decide where to poop
func _initiate_pooping_sequence():
	var poop_count = 0
	for body in poop_area.get_overlapping_bodies():
		if body.is_in_group("poop"):
			poop_count += 1
			
	if poop_count > 3:
		current_state = State.POOPING_ON_MAP
	else:
		current_state = State.POOPING_IN_TOILET
	
	target_position = Vector3.ZERO
	has_started_pooping = false
