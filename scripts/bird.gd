# extends CharacterBody3D

# # Greg's movement speed
# const SPEED = 3.0
# const FLY_SPEED = 5.0
# const FLIGHT_HEIGHT_OFFSET = 0.6 # How high Greg flies above his targets

# # Animation names
# const ANIM_IDLE = "greg_idle"
# const ANIM_FLY = "greg_fly"

# # States for Greg's behavior
# enum State {
# 	GOING_TO_BIRDHOUSE,
# 	IDLE,
# 	GOING_TO_FOOD,
# 	FOLLOWING_PLAYER,
# 	EATING,
# 	POOPING_IN_TOILET,
# 	POOPING_ON_MAP
# }

# # Public variables that can be set in the editor
# @export var birdhouse_area: Area3D
# @export var poop_area: Area3D
# @export var feed_area: Area3D
# @export var player: CharacterBody3D
# @export var poop_scene: PackedScene

# @onready var animation_player: AnimationPlayer = $bird/AnimationPlayer

# # Greg's internal state
# var current_state = State.GOING_TO_BIRDHOUSE
# var hunger = 0.0
# var poop_urgency = 0.0
# var is_toilet_clean = true
# var idle_behavior_timer = 0.0
# var target_position: Vector3

# func _ready():
# 	motion_mode = MOTION_MODE_FLOATING
# 	# Start the idle behavior timer
# 	idle_behavior_timer = 3.0


# func _physics_process(delta):
# 	# Update needs over time
# 	hunger += delta
# 	poop_urgency += delta

# 	# State machine logic
# 	match current_state:
# 		State.GOING_TO_BIRDHOUSE:
# 			_go_to_birdhouse_state(delta)
# 		State.IDLE:
# 			_idle_behavior_state(delta)
# 		State.GOING_TO_FOOD:
# 			_going_to_food_state(delta)
# 		State.FOLLOWING_PLAYER:
# 			_following_player_state(delta)
# 		State.EATING:
# 			_eating_state(delta)
# 		State.POOPING_IN_TOILET:
# 			_pooping_in_toilet_state(delta)
# 		State.POOPING_ON_MAP:
# 			_pooping_on_map_state(delta)

# 	# Check if Greg needs to poop
# 	if poop_urgency > 30 and current_state != State.POOPING_IN_TOILET and current_state != State.POOPING_ON_MAP:
# 		_check_toilet()

# 	# Orient the bird model to face the direction of movement.
# 	if velocity.length_squared() > 0.01:
# 		# The model's front is +Z, but looking_at points -Z.
# 		# So, we point the back of the model (-Z) to the opposite of the velocity.
# 		$bird.transform.basis = Basis.looking_at(-velocity.normalized(), Vector3.UP)

# 	# Basic movement and animation
# 	move_and_slide()
# 	_update_animation()

# func _update_animation():
# 	if velocity.length_squared() > 0.1:
# 		animation_player.play(ANIM_FLY)
# 	else:
# 		animation_player.play(ANIM_IDLE)

# func _go_to_birdhouse_state(delta):
# 	print("going to birdhouse")
# 	print("Birdhouse area overlapping bodies: ", birdhouse_area.get_overlapping_bodies())
# 	# If we are already in the birdhouse, switch to idle behavior.
# 	if birdhouse_area.get_overlapping_bodies().has(self):
# 		velocity = Vector3.ZERO
# 		current_state = State.IDLE
# 		return

# 	# Move towards the center of the birdhouse area.
# 	if birdhouse_area:
# 		var target_pos = birdhouse_area.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
# 		var direction = (target_pos - global_position).normalized()
# 		velocity = direction * SPEED
	
# 	# If there's food in the feed area, go eat it
# 	if feed_area and not feed_area.get_overlapping_bodies().is_empty():
# 		current_state = State.GOING_TO_FOOD
# 	# If Greg gets too hungry, he starts following the player
# 	elif hunger > 50:
# 		current_state = State.FOLLOWING_PLAYER

# func _idle_behavior_state(delta):
# 	print("in idle_behavior_state")
# 	idle_behavior_timer -= delta
# 	if idle_behavior_timer <= 0:
# 		# Timer is up. First, check if we've left the birdhouse area.
# 		if not birdhouse_area.get_overlapping_bodies().has(self):
# 			current_state = State.GOING_TO_BIRDHOUSE
# 			return

# 		# If we are inside the area, pick a new idle behavior.
# 		var chance = randf()
		
# 		# Get the collision shape to calculate random points within its bounds
# 		var shape_owner = birdhouse_area.get_children().filter(func(c): return c is CollisionShape3D)[0]
# 		if shape_owner and shape_owner.shape is BoxShape3D:
# 			var box_extents = shape_owner.shape.size / 2.0
# 			# Use the collision shape's transform to correctly map the random point to global space
# 			# var shape_transform = shape_owner.global_transform
# 			# var random_local_point = Vector3(randf_range(-box_extents.x, box_extents.x), 0, randf_range(-box_extents.z, box_extents.z))
			
# 			var area_center = birdhouse_area.global_position
# 			var random_local_point = Vector3(randf_range(-box_extents.x, box_extents.x), 0, randf_range(-box_extents.z, box_extents.z))


# 			print("self global position: ", self.global_position)
# 			# print("shape owner pos: ", shape_transform.origin)
			
# 			if chance < 0.05: # 5% chance to fly around
# 				print_rich("[color=yellow]fly")
# 				random_local_point.y = 5.0 # Fly high
# 				# target_position = shape_transform * Vector3(random_local_point.x, random_local_point.y, random_local_point.z)
# 				target_position = area_center + random_local_point
# 				idle_behavior_timer = 10.0 # Fly for 10 seconds
# 			elif chance < 0.15: # 15% chance to "walk" (fly low) around
# 				print_rich("[color=yellow]walking")
# 				random_local_point.y = FLIGHT_HEIGHT_OFFSET
# 				# target_position = shape_transform * Vector3(random_local_point.x, random_local_point.y, random_local_point.z)
# 				target_position = area_center + random_local_point
# 				idle_behavior_timer = 5.0 # "Walk" for 5 seconds
# 			else: # 80% chance to idle
# 				print_rich("[color=yellow]idle")
# 				velocity = Vector3.ZERO
# 				idle_behavior_timer = 3.0 # Idle for 3 seconds
# 				return
# 		else: # Default behavior if no valid box shape is found
# 			velocity = Vector3.ZERO
# 			idle_behavior_timer = 3.0
# 			return

# 	# If the timer is not up, continue moving towards the current target.
# 	var direction = (target_position - global_position).normalized()
# 	velocity = direction * SPEED
# 	if global_position.distance_to(target_position) < 0.5:
# 		velocity = Vector3.ZERO

# func _going_to_food_state(delta):
# 	if feed_area:
# 		var target_pos = feed_area.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
# 		var direction = (target_pos - global_position).normalized()
# 		velocity = direction * SPEED
		
# 		# If close enough, eat the food
# 		if global_position.distance_to(target_pos) < 1.5:
# 			# Consume the food (for now, just destroy the first food item found)
# 			var food = feed_area.get_overlapping_bodies()[0]
# 			food.queue_free()
# 			current_state = State.EATING

# func _following_player_state(delta):
# 	# In this state, Greg follows the player
# 	if player:
# 		var target_pos = player.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
# 		var direction = (target_pos - global_position).normalized()
# 		velocity = direction * SPEED
		
# 		# If Greg is close enough to the player, he "sits" on their head
# 		if global_position.distance_to(target_pos) < 1.5:
# 			global_position = player.global_position + Vector3(0, 1, 0) # Sit on head
# 			velocity = Vector3.ZERO

# func _eating_state(delta):
# 	# For now, just reset hunger and go back to birdhouse
# 	hunger = 0.0
# 	current_state = State.GOING_TO_BIRDHOUSE

# func _pooping_in_toilet_state(delta):
# 	# Move to the toilet
# 	if poop_area:
# 		var target_pos = poop_area.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
# 		var direction = (target_pos - global_position).normalized()
# 		velocity = direction * SPEED
		
# 		# If close enough, "poop" and reset urgency
# 		if global_position.distance_to(target_pos) < 1.0:
# 			poop_urgency = 0.0
# 			current_state = State.GOING_TO_BIRDHOUSE

# func _pooping_on_map_state(delta):
# 	# Find a random spot near the current position to poop
# 	var random_offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
# 	var poop_position = global_position + random_offset
	
# 	var direction = (poop_position - global_position).normalized()
# 	velocity = direction * SPEED
	
# 	if global_position.distance_to(poop_position) < 0.5:
# 		# Instance the poop scene here
# 		if poop_scene:
# 			var poop_instance = poop_scene.instantiate()
# 			get_parent().add_child(poop_instance) # Add to the main scene
# 			poop_instance.global_position = global_position
# 		poop_urgency = 0.0
# 		current_state = State.GOING_TO_BIRDHOUSE

# # Public function for the player to feed Greg
# func feed():
# 	current_state = State.EATING

# # Private function to check toilet status
# func _check_toilet():
# 	if is_toilet_clean:
# 		current_state = State.POOPING_IN_TOILET
# 	else:
# 		current_state = State.POOPING_ON_MAP

extends CharacterBody3D

# Greg's movement speed
const SPEED = 3.0
const FLY_SPEED = 5.0
const FLIGHT_HEIGHT_OFFSET = 0.6 # How high Greg flies above his targets

# Collision avoidance settings
const AVOIDANCE_DISTANCE = 2.0 # How far ahead to check for obstacles
const AVOIDANCE_FORCE = 1.5 # How strong the avoidance steering is
const RAYCAST_COUNT = 5 # Number of raycasts in a fan pattern

# World exploration limits
const WORLD_EXPLORE_RADIUS = 20.0 # How far from starting position to explore
const WORLD_EXPLORE_HEIGHT_MIN = 3.0 # Minimum flight height when exploring
const WORLD_EXPLORE_HEIGHT_MAX = 25.0 # Maximum flight height when exploring

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
var is_toilet_clean = true
var idle_behavior_timer = 0.0
var target_position: Vector3
var desired_velocity: Vector3 = Vector3.ZERO
var avoidance_velocity: Vector3 = Vector3.ZERO
var world_explore_center: Vector3
var world_explore_target: Vector3

func _ready():
	motion_mode = MOTION_MODE_FLOATING
	# Start the idle behavior timer
	idle_behavior_timer = 3.0
	world_explore_center = global_position

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
		State.EXPLORING_WORLD:
			_exploring_world_state(delta)

	# Check if Greg needs to poop
	if poop_urgency > 30 and current_state != State.POOPING_IN_TOILET and current_state != State.POOPING_ON_MAP:
		_check_toilet()

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
	print("going to birdhouse")
	print("Birdhouse area overlapping bodies: ", birdhouse_area.get_overlapping_bodies())
	# If we are already in the birdhouse, switch to idle behavior.
	if birdhouse_area.get_overlapping_bodies().has(self):
		desired_velocity = Vector3.ZERO
		current_state = State.IDLE
		return

	# Move towards the center of the birdhouse area.
	if birdhouse_area:
		var target_pos = birdhouse_area.global_position + Vector3.UP * FLIGHT_HEIGHT_OFFSET
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
	
	if idle_behavior_timer <= 0:
		# Timer is up. First, check if we've left the birdhouse area.
		if not birdhouse_area.get_overlapping_bodies().has(self):
			current_state = State.GOING_TO_BIRDHOUSE
			return
		
		# Get the collision shape to calculate random points within its bounds
		var shape_owner = birdhouse_area.get_children().filter(func(c): return c is CollisionShape3D)[0]
		if shape_owner and shape_owner.shape is BoxShape3D:
			var box_extents = shape_owner.shape.size / 2.0
			var area_center = birdhouse_area.global_position
			

			# If we are inside the area, pick a new idle behavior.
			var chance = randf()
			# Generate a random point within the birdhouse area
			var random_offset = Vector3(
				randf_range(-box_extents.x, box_extents.x),
				0,
				randf_range(-box_extents.z, box_extents.z)
			)
			# if chance < 0.15: # 5% chance to fly around
			# 	print_rich("[color=yellow]fly")
			# 	random_offset.y = 5.0 # Fly high
			# 	target_position = area_center + random_offset
			# 	idle_behavior_timer = 25.0
			# 	start_world_exploration()
			# elif chance < 0.85: # 15% chance to "walk" (fly low) around
			print_rich("[color=yellow]walking")
			random_offset.y = FLIGHT_HEIGHT_OFFSET
			target_position = area_center + random_offset
			idle_behavior_timer = 5.0
			# else: # 80% chance to idle
			# print_rich("[color=yellow]idle")
			# desired_velocity = Vector3.ZERO
			# idle_behavior_timer = 3.0
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
		
		# If close enough, "poop" and reset urgency
		if global_position.distance_to(target_pos) < 1.0:
			poop_urgency = 0.0
			current_state = State.GOING_TO_BIRDHOUSE

func _pooping_on_map_state(delta):
	# Find a random spot near the current position to poop
	var random_offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	var poop_position = global_position + random_offset
	
	var direction = (poop_position - global_position).normalized()
	desired_velocity = direction * SPEED
	
	if global_position.distance_to(poop_position) < 0.5:
		# Instance the poop scene here
		if poop_scene:
			var poop_instance = poop_scene.instantiate()
			get_parent().add_child(poop_instance) # Add to the main scene
			poop_instance.global_position = global_position
		poop_urgency = 0.0
		current_state = State.GOING_TO_BIRDHOUSE

func _exploring_world_state(delta):
	# If we don't have a target or reached the current target, pick a new one
	if world_explore_target == Vector3.ZERO or global_position.distance_to(world_explore_target) < 2.0:
		_pick_new_world_explore_target()
	
	# Move toward the exploration target
	var direction = (world_explore_target - global_position).normalized()
	desired_velocity = direction * FLY_SPEED
	
	# Optional: Return to birdhouse if we get too far or after some time
	if global_position.distance_to(world_explore_center) > WORLD_EXPLORE_RADIUS * 1.5:
		current_state = State.GOING_TO_BIRDHOUSE

func _pick_new_world_explore_target():
	# Generate a random point within the exploration radius
	var random_angle = randf() * TAU # Random angle in radians
	var random_distance = randf_range(5.0, WORLD_EXPLORE_RADIUS)
	var random_height = randf_range(WORLD_EXPLORE_HEIGHT_MIN, WORLD_EXPLORE_HEIGHT_MAX)
	
	# Calculate the new target position
	var offset = Vector3(
		cos(random_angle) * random_distance,
		random_height,
		sin(random_angle) * random_distance
	)
	
	world_explore_target = world_explore_center + offset
	print("New world explore target: ", world_explore_target)

# Public method to start world exploration:
func start_world_exploration():
	"""Call this method to make the bird start exploring the world randomly."""
	current_state = State.EXPLORING_WORLD
	world_explore_center = global_position # Update center to current position
	world_explore_target = Vector3.ZERO # Reset target to force new target selection
	print("Greg started exploring the world!")

# Public method to set exploration center:
func set_world_exploration_center(center_position: Vector3):
	"""Set a specific center point for world exploration."""
	world_explore_center = center_position

# Public method to stop world exploration and return to birdhouse:
func stop_world_exploration():
	"""Stop world exploration and return to normal behavior."""
	current_state = State.GOING_TO_BIRDHOUSE
	print("Greg stopped exploring and is returning to birdhouse.")

# Public function for the player to feed Greg
func feed():
	current_state = State.EATING

# Private function to check toilet status
func _check_toilet():
	if is_toilet_clean:
		current_state = State.POOPING_IN_TOILET
	else:
		current_state = State.POOPING_ON_MAP
