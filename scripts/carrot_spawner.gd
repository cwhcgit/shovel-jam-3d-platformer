extends Node3D

## Carrot Spawner Script
##
## This script periodically spawns a given scene (like a carrot) at a random
## horizontal position within a specified Area3D and lets it fall.

# The scene to spawn (e.g., the carrot). Assign this in the Inspector.
@export var item_to_spawn: PackedScene

# The Area3D that defines the spawn boundaries. Assign this in the Inspector.
@export var spawn_area: Area3D

# The time in seconds between each spawn.
@export var spawn_interval: float = 2.0

# The timer node that will trigger the spawning.
@onready var spawn_timer: Timer = $SpawnTimer

# Whether to apply random rotation to spawned objects
@export var random_rotation: bool = true

func _ready():
	# --- Basic Checks ---
	if not item_to_spawn:
		printerr("Carrot Spawner: 'item_to_spawn' is not set. Disabling spawner.")
		set_process(false)
		return
	if not spawn_area:
		printerr("Carrot Spawner: 'spawn_area' is not set. Disabling spawner.")
		set_process(false)
		return

	# --- Timer Setup ---
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	"""
	Called every time the spawn timer finishes.
	This function handles the creation and positioning of a new item.
	"""
	if not item_to_spawn or not spawn_area:
		return

	# Get the shape from the spawn area to determine its bounds
	var collision_shape = spawn_area.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		printerr("Carrot Spawner: No CollisionShape3D found as a child of the spawn_area.")
		return

	# We assume the shape is a BoxShape3D for calculating bounds
	if not collision_shape.shape is BoxShape3D:
		printerr("Carrot Spawner: The spawn_area's collision shape must be a BoxShape3D.")
		return
		
	var box_shape: BoxShape3D = collision_shape.shape
	var extents = box_shape.size / 2.0

	# --- Calculate Random Position ---
	# Get a random point within the box's volume
	var random_pos = Vector3(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y),
		randf_range(-extents.z, extents.z)
	)
	
	# Convert the local random position to a global world position
	var spawn_position = spawn_area.to_global(random_pos)

	# --- Instantiate and Place the Item ---
	var new_item = item_to_spawn.instantiate()
	
	# --- Apply Random Rotation ---
	if random_rotation:
		# Generate random rotation angles for each axis (in radians)
		var random_rotation_x = randf_range(0.0, TAU)  # TAU = 2π
		var random_rotation_y = randf_range(0.0, TAU)
		var random_rotation_z = randf_range(0.0, TAU)
		
		# Apply the random rotation
		new_item.rotation = Vector3(random_rotation_x, random_rotation_y, random_rotation_z)
		
	# Add the new item to the scene tree (as a sibling of this spawner node)
	get_parent().add_child(new_item)
	
	# Set its global position
	new_item.global_position = spawn_position
