extends Node3D

@export var target_vehicle: VehicleBody3D  # Your car
@export var follow_speed := 10.0           # Smooth follow speed
@export var camera_height := 5.0           # Height above car
@export var camera_distance := 15.0        # Default distance behind car
@export var mouse_sensitivity := 0.003     # Mouse sensitivity
@export var min_pitch := -1.2              # Minimum vertical angle (radians)
@export var max_pitch := 1.2               # Maximum vertical angle (radians)

@onready var camera = $Camera3D

var yaw := 0.0
var pitch := 0.2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Capture mouse for rotation

func _input(event):
	if event is InputEventMouseMotion:
		# Natural vertical rotation (not inverted)
		yaw -= event.relative.x * mouse_sensitivity   # left/right
		pitch += event.relative.y * mouse_sensitivity # up/down corrected
		pitch = clamp(pitch, min_pitch, max_pitch)

func _physics_process(delta):
	if not target_vehicle:
		return

	# Vehicle position
	var car_pos = target_vehicle.global_position

	# Calculate camera offset
	var offset = Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * camera_distance
	offset.y += camera_height

	# Smooth follow
	global_position = global_position.lerp(car_pos + offset, follow_speed * delta)

	# Look at car
	look_at(car_pos + Vector3.UP, Vector3.UP)
