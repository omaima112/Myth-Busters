# This script should be attached to the root Environment node in level_2.tscn
extends Node3D

var camera: Camera3D
var has_error = false

func _ready():
	print("=== LEVEL 2 INITIALIZING ===")
	
	# Wait for scene to be in tree
	await get_tree().process_frame
	
	# RESET ORBS COUNT FOR LEVEL 2
	# Count how many orbs/barrels are in this level
	var orbs_in_level = count_orbs()
	print("🔋 Orbs found in Level 2: ", orbs_in_level)
	
	# Reset GameManager for Level 2
	if GameManager:
		GameManager.initialize_orbs(orbs_in_level)
		print("✅ GameManager initialized with ", orbs_in_level, " orbs for Level 2")
	else:
		print("⚠️ GameManager not found!")
	
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

func _input(event: InputEvent):
	# ✅ CRITICAL FIX: Only trigger Q input if game is NOT paused (paused = in a menu/dialog)
	if get_tree().paused:
		return
	
	# Press Q to open the quiz
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			print("🎓 Q pressed — loading quiz...")
			get_tree().change_scene_to_file("res://Scenes/Levels/quiz.tscn")

# Count orbs in the level
func count_orbs() -> int:
	var count = 0
	# Look for nodes with the orb script or name containing "orb"
	for child in get_tree().get_nodes_in_group("orbs"):
		count += 1
	
	# If no group found, search by node name
	if count == 0:
		for child in get_all_children(self):
			if "orb" in child.name.to_lower():
				count += 1
	
	# Subtract 1 because we're counting before the first orb is collected
	# The HUD will show one higher otherwise
	if count > 0:
		count -= 1
	
	return count

# Get all children recursively
func get_all_children(node: Node) -> Array:
	var children = []
	for child in node.get_children():
		children.append(child)
		children.append_array(get_all_children(child))
	return children

# Create a default camera if none exists
func create_camera():
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 8, 20)
	
	# Add child first so it's in the tree
	add_child(camera)
	
	# Now we can use look_at since node is in tree
	camera.look_at(Vector3(0, 2, 0), Vector3.UP)
	camera.current = true
	
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
