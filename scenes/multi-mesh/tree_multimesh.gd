extends Node3D

class_name TreeBoundaryWall

@export var tree_scenes: Array[PackedScene] = []  # Array of different tree scenes
@export var boundary_size: Vector2 = Vector2(100, 100)  # World boundary dimensions
@export var tree_spacing: float = 5.0  # Distance between trees
@export var tree_count_per_side: int = 20  # Trees per wall side
@export var wall_thickness: float = 10.0  # How thick the tree wall is
@export var height_variation: float = 2.0  # Random height offset
@export var rotation_variation: float = 45.0  # Random rotation in degrees
@export var scale_variation: float = 0.3  # Random scale variation (0.0 to 1.0)

var tree_instances: Array[Node3D] = []

func _ready():
	create_tree_boundary()

func create_tree_boundary():
	if tree_scenes.is_empty():
		print("Warning: No tree scenes provided!")
		return
	
	# Generate tree positions and create instances
	generate_tree_instances()

func calculate_total_trees() -> int:
	# Calculate trees for all four sides of the boundary
	var trees_per_side = tree_count_per_side
	var total_trees = 0
	
	# Add trees for each side
	total_trees += trees_per_side * 4
	
	# Add trees for wall thickness (multiple rows)
	var rows = max(1, int(wall_thickness / tree_spacing))
	total_trees *= rows
	
	return total_trees

func generate_tree_instances():
	var half_boundary = boundary_size / 2.0
	
	# Number of rows for wall thickness
	var rows = max(1, int(wall_thickness / tree_spacing))
	
	# Generate trees for each row
	for row in range(rows):
		var row_offset = (row - rows / 2.0) * tree_spacing
		
		# Top wall (Z positive)
		for i in range(tree_count_per_side):
			var x = lerp(-half_boundary.x, half_boundary.x, float(i) / (tree_count_per_side - 1))
			var z = half_boundary.y + row_offset
			create_tree_instance(Vector3(x, 0, z))
		
		# Bottom wall (Z negative)
		for i in range(tree_count_per_side):
			var x = lerp(-half_boundary.x, half_boundary.x, float(i) / (tree_count_per_side - 1))
			var z = -half_boundary.y + row_offset
			create_tree_instance(Vector3(x, 0, z))
		
		# Left wall (X negative)
		for i in range(tree_count_per_side):
			var x = -half_boundary.x + row_offset
			var z = lerp(-half_boundary.y, half_boundary.y, float(i) / (tree_count_per_side - 1))
			create_tree_instance(Vector3(x, 0, z))
		
		# Right wall (X positive)
		for i in range(tree_count_per_side):
			var x = half_boundary.x + row_offset
			var z = lerp(-half_boundary.y, half_boundary.y, float(i) / (tree_count_per_side - 1))
			create_tree_instance(Vector3(x, 0, z))

func create_tree_instance(base_position: Vector3):
	# Randomly select a tree scene
	var random_scene = tree_scenes[randi() % tree_scenes.size()]
	var tree_instance = random_scene.instantiate() as Node3D
	
	if not tree_instance:
		print("Error: Could not instantiate tree scene")
		return
	
	# Add random variations
	var height_offset = randf_range(-height_variation, height_variation)
	var _position = base_position + Vector3(0, height_offset, 0)
	
	# Random rotation around Y axis
	var rotation_y = deg_to_rad(randf_range(-rotation_variation, rotation_variation))
	
	# Random scale
	var scale_factor = 1.0 + randf_range(-scale_variation, scale_variation)
	
	# Apply transform
	tree_instance.position = _position
	tree_instance.rotation.y = rotation_y
	tree_instance.scale = Vector3.ONE * scale_factor
	
	# Add to scene
	add_child(tree_instance)
	tree_instances.append(tree_instance)
