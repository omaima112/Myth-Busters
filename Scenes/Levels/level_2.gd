# This script should be attached to the root Environment node in level_2.tscn
extends Node3D

var camera: Camera3D
var has_error = false

func _ready():
	print("=== LEVEL 2 INITIALIZING ===")
	
	# Ensure camera exists
	camera = get_tree().root.get_viewport().get_camera_3d()
	
	if camera == null:
		print("⚠️ WARNING: No camera found in scene!")
		camera = find_child("Camera3D")
		
		if camera == null:
			print("❌ ERROR: No Camera3D node - creating one!")
			create_camera()
		else:
			print("✓ Found Camera3D node")
			camera.current = true
	else:
		print("✓ Camera already exists")
	
	# Check environment
	if not get_tree().root.get_viewport().get_camera_3d():
		print("❌ ERROR: Camera not properly set as current!")
		has_error = true
	
	# Check WorldEnvironment exists
	var world_env = find_child("WorldEnvironment")
	if world_env == null:
		print("⚠️ WARNING: No WorldEnvironment found")
	else:
		print("✓ WorldEnvironment found")
	
	# Check for light
	var light = find_child("DirectionalLight3D")
	if light == null:
		print("⚠️ WARNING: No DirectionalLight3D found")
	else:
		print("✓ DirectionalLight3D found")
	
	print("=== LEVEL 2 READY ===")
	
	# Debug: Print render viewport info
	await get_tree().process_frame
	print("Viewport color: ", get_tree().root.get_viewport().get_clear_mode())

# Create a default camera if none exists
func create_camera():
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 8, 20)
	camera.look_at(Vector3(0, 2, 0), Vector3.UP)
	camera.current = true
	add_child(camera)
	print("✓ Created new Camera3D at position: ", camera.position)

# Adjust camera for better view
func adjust_camera():
	if camera:
		# Calculate level center
		var csg = find_child("CSGCombiner3D")
		if csg:
			var center = csg.position
			camera.position = center + Vector3(0, 15, 30)
			camera.look_at(center, Vector3.UP)
			print("✓ Adjusted camera to focus on level: ", camera.position)
