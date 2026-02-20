# This script should be attached to the root Environment node in level_2.tscn
extends Node3D

var camera: Camera3D
var has_error = false

func _ready():
	await get_tree().process_frame
	
	# Reset orb count for Level 2
	var orbs_in_level = count_orbs()
	
	if GameManager:
		GameManager.initialize_orbs(orbs_in_level)
	
	# Ensure camera exists
	camera = get_tree().root.get_viewport().get_camera_3d()
	
	if camera == null:
		camera = find_child("Camera3D")
		
		if camera == null:
			create_camera()
		else:
			camera.current = true
	
	if not get_tree().root.get_viewport().get_camera_3d():
		has_error = true

func _input(event: InputEvent):
	# Only trigger Q input if game is NOT paused (paused = in a menu/dialog)
	if get_tree().paused:
		return
	
	# Press Q to open the quiz
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			get_tree().change_scene_to_file("res://Scenes/Levels/quiz.tscn")

# Count orbs in the level
func count_orbs() -> int:
	var count = 0
	for child in get_tree().get_nodes_in_group("orbs"):
		count += 1
	
	# If no group found, search by node name
	if count == 0:
		for child in get_all_children(self):
			if "orb" in child.name.to_lower():
				count += 1
	
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
	add_child(camera)
	camera.look_at(Vector3(0, 2, 0), Vector3.UP)
	camera.current = true

# Adjust camera for better view
func adjust_camera():
	if camera:
		var csg = find_child("CSGCombiner3D")
		if csg:
			var center = csg.position
			camera.position = center + Vector3(0, 15, 30)
			camera.look_at(center, Vector3.UP)
