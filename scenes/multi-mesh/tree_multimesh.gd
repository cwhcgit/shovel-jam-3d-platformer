extends Node3D

# @onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D

# # The scene containing the tree mesh. Assign this in the Inspector.
# @export var tree_scene: PackedScene

# # Define the area where trees should be placed
# const SPREAD_X = 100.0
# const SPREAD_Z = 100.0
# const INSTANCE_COUNT = 100

# func _ready():
# 	if not tree_scene:
# 		printerr("Tree scene is not set in the inspector for TreeMultiMesh.")
# 		return

# 	# 1. Create and configure a new MultiMesh resource
# 	var multimesh = MultiMesh.new()
# 	multimesh.transform_format = MultiMesh.TRANSFORM_3D
# 	multimesh.instance_count = INSTANCE_COUNT

# 	# 2. Get the mesh from the provided scene
# 	var temp_instance = tree_scene.instantiate()
# 	var mesh_instance = _find_first_node_of_type(temp_instance, MeshInstance3D)

# 	if mesh_instance and mesh_instance.mesh:
# 		multimesh.mesh = mesh_instance.mesh
# 	else:
# 		printerr("Could not find a MeshInstance3D with a valid mesh in the provided tree scene.")
# 		temp_instance.free() # Clean up the unused instance
# 		return
	
# 	temp_instance.free() # Clean up the unused instance

# 	# 3. Assign the fully configured resource to the node
# 	multimesh_instance.multimesh = multimesh

# 	# 4. Populate the transforms
# 	randomize()
# 	for i in range(multimesh.instance_count):
# 		# --- Position ---
# 		var x_pos = randf_range(-SPREAD_X / 2.0, SPREAD_X / 2.0)
# 		var z_pos = randf_range(-SPREAD_Z / 2.0, SPREAD_Z / 2.0)
# 		var position = Vector3(x_pos, 0, z_pos)
		
# 		# --- Rotation ---
# 		var y_rotation = randf_range(0, TAU)
		
# 		# --- Scale ---
# 		var scale_factor = randf_range(0.8, 1.2)
# 		var scale = Vector3(scale_factor, scale_factor, scale_factor)
		
# 		# Create the transform with the random values
# 		var transform = Transform3D(Basis.from_euler(Vector3(0, y_rotation, 0)), position).scaled(scale)
		
# 		# Set the transform for the instance
# 		multimesh.set_instance_transform(i, transform)

# # Helper function to find the first node of a given type recursively
# func _find_first_node_of_type(node, type):
# 	if node is type:
# 		return node
# 	for child in node.get_children():
# 		var result = _find_first_node_of_type(child, type)
# 		if result:
# 			return result
# 	return null
