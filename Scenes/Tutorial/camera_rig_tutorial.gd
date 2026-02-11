extends Node3D

# References
@export var target_vehicle: NodePath
@export var distance: float = 15.0
@export var height: float = 5.0
@export var sensitivity: float = 0.005

var vehicle: Node3D
var camera: Camera3D
var angle_h: float = 0.0  # Horizontal angle
var angle_v: float = 0.0  # Vertical angle

func _ready() -> void:
	print("=== SIMPLE ORBIT CAMERA START ===")
	
	# Get camera child
	camera = $Camera3D
	if not camera:
		print("❌ NO CAMERA FOUND!")
		return
	
	camera.current = true
	print("✅ Camera set as current")
	
	# Get vehicle
	if target_vehicle:
		vehicle = get_node(target_vehicle)
	else:
		vehicle = get_parent().get_node("Jeep")
	
	if vehicle:
		print("✅ Vehicle found: ", vehicle.name)
	else:
		print("❌ Vehicle not found")
	
	set_process_input(true)
	set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion = event as InputEventMouseMotion
		# Simple mouse movement
		angle_h -= motion.relative.x * sensitivity
		angle_v -= motion.relative.y * sensitivity
		# Limit vertical
		angle_v = clamp(angle_v, -70.0, 70.0)

func _process(_delta: float) -> void:
	if not vehicle or not camera:
		return
	
	# Convert to radians
	var h = deg_to_rad(angle_h)
	var v = deg_to_rad(angle_v)
	
	# Simple orbit math
	var x = sin(h) * distance * cos(v)
	var y = sin(v) * distance + height
	var z = cos(h) * distance * cos(v)
	
	# Set camera position
	global_position = vehicle.global_position + Vector3(x, y, z)
	
	# Look at vehicle
	camera.look_at(vehicle.global_position + Vector3(0, 1, 0), Vector3.UP)
