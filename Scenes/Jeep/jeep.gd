extends VehicleBody3D

@export var can_drive := true

# === VEHICLE SCALING (Safe - doesn't override physics) ===
@export var vehicle_scale := 1.0  # Scale multiplier (1.0 = normal, 1.5 = 50% bigger)
@export var apply_scale_on_ready := true  # Auto-scale when scene starts

# Toy Car Tuning (adjust in Inspector!)
@export var max_engine_force := 1200.0     # High relative to low mass = snappy!
@export var max_brake_force := 20.0        # Light braking for drifts
@export var handbrake_force := 40.0        # Strong skid for fun
@export var max_steer_angle := 0.7         # Wide turns
@export var steer_speed := 8.0             # Instant response
@export var invert_steering := false       # NEW: Option to invert steering

# === NITRO BOOST SETTINGS ===
@export var nitro_boost_multiplier := 2.5  # 2.5x engine power when active
@export var max_nitro := 100.0             # Max nitro capacity
@export var nitro_drain_rate := 20.0      # Nitro consumed per second
@export var nitro_recharge_rate := 10.0   # Nitro recharged per second (when not boosting)
@export var nitro_cooldown := 0.5         # Seconds before recharge starts

var current_nitro := 100.0
var nitro_cooldown_timer := 0.0
var is_boosting := false

@onready var engine_sound: AudioStreamPlayer3D = $EngineSound
@onready var horn_sound: AudioStreamPlayer3D = $HornSound

# Engine sound tuning
@export var idle_pitch := 0.8      # Low hum at idle
@export var max_pitch := 2.0       # High rev at full throttle
@export var pitch_smoothing := 5.0 # Smooth pitch changes

@export var wheel_friction_slip := 2.0
@export var suspension_travel := 0.3
@export var suspension_stiffness := 25.0
@export var damping_compression := 0.8
@export var damping_relaxation := 1.0

var current_pitch := idle_pitch

var initial_position := Vector3.ZERO  # Store initial position
var initial_rotation := Vector3.ZERO  # Store initial rotation
var initial_mesh_scales = {}  # Store original mesh scales
var initial_wheel_positions = {}  # Store original wheel positions

func _ready():
	# Store initial transform
	initial_position = global_position
	initial_rotation = rotation
	
	# Store initial scales of all meshes and wheels
	for child in get_children():
		if child is MeshInstance3D:
			initial_mesh_scales[child.name] = child.scale
		elif child is VehicleWheel3D:
			initial_wheel_positions[child.name] = child.position
	
	# Apply scaling if enabled
	if apply_scale_on_ready and vehicle_scale != 1.0:
		scale_vehicle(vehicle_scale)
	
	# Auto-tune all wheels (toy car feel)
	for wheel in get_children():
		if wheel is VehicleWheel3D:
			# Grip & suspension (all wheels)
			wheel.wheel_friction_slip = wheel_friction_slip
			wheel.suspension_travel = suspension_travel * vehicle_scale
			wheel.suspension_stiffness = suspension_stiffness
			wheel.damping_compression = damping_compression
			wheel.damping_relaxation = damping_relaxation
			
			# Front wheels only: steering
			if wheel.position.z > 0:  # Assuming Z > 0 = front
				wheel.use_as_steering = true
			
			# Rear wheels only: drive
			if wheel.position.z < 0:  # Z < 0 = rear
				wheel.use_as_traction = true

# Scale the vehicle properly (meshes and wheels, not physics body)
func scale_vehicle(scale_factor: float) -> void:
	if scale_factor <= 0:
		print("❌ Invalid scale factor! Must be > 0")
		return
	
	print("🚗 Scaling vehicle to: ", scale_factor, "x")
	
	# IMPORTANT: Don't scale the VehicleBody3D itself!
	# Instead, scale all child meshes and wheels
	
	# Scale all MeshInstance3D nodes
	for child in get_children():
		if child is MeshInstance3D:
			var original_scale = initial_mesh_scales.get(child.name, child.scale)
			child.scale = original_scale * scale_factor
			print("  ✓ Scaled mesh: ", child.name, " to ", child.scale)
		
		# Scale wheel positions (so they move further from center)
		elif child is VehicleWheel3D:
			var original_pos = initial_wheel_positions.get(child.name, child.position)
			child.position = original_pos * scale_factor
			child.suspension_travel = suspension_travel * scale_factor
			print("  ✓ Scaled wheel: ", child.name, " position to ", child.position)
	
	# Adjust main body position so it sits on ground properly
	global_position.y = initial_position.y * scale_factor
	
	print("✅ Vehicle scaled to: ", scale_factor, "x")
	print("✅ New position Y: ", global_position.y)
	print("✅ Physics body NOT scaled (avoids override issues)")

# Reset vehicle (with proper scaling)
func reset_vehicle():
	print("🔄 Resetting vehicle...")
	
	# Reset position
	global_position = initial_position
	global_position.y = initial_position.y * vehicle_scale
	rotation = initial_rotation
	
	# Reset all meshes to scaled size
	for child in get_children():
		if child is MeshInstance3D:
			var original_scale = initial_mesh_scales.get(child.name, Vector3.ONE)
			child.scale = original_scale * vehicle_scale
		
		elif child is VehicleWheel3D:
			var original_pos = initial_wheel_positions.get(child.name, child.position)
			child.position = original_pos * vehicle_scale
			child.suspension_travel = suspension_travel * vehicle_scale
	
	# Reset physics
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Reset nitro
	current_nitro = max_nitro
	nitro_cooldown_timer = 0.0
	is_boosting = false
	
	print("✅ Vehicle reset!")

func _physics_process(delta):
	
	# Reset on 'R' key
	if Input.is_action_just_pressed("Reset"):  # Default 'R' key
		reset_vehicle()
		
	var throttle = Input.get_action_strength("Gas") - Input.get_action_strength("Brake")
	
	# STEERING FIX: Check if steering should be inverted
	var steer_input = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	if invert_steering:
		steer_input = -steer_input  # Flip steering direction
	
	var handbrake = Input.is_action_pressed("Handbrake")
	
	if not can_drive:
		engine_force = 0.0
		brake = 100.0  # Lock wheels
		steering = 0.0
		return  # Skip all driving logic
	
	# === NITRO BOOST LOGIC ===
	# Check if player is trying to boost (Left Shift key)
	var nitro_input = Input.is_key_pressed(KEY_SHIFT)
	
	# Only boost if moving forward and has nitro
	if nitro_input and throttle > 0 and current_nitro > 0:
		is_boosting = true
		current_nitro -= nitro_drain_rate * delta
		current_nitro = max(0.0, current_nitro)  # Clamp to 0
		nitro_cooldown_timer = nitro_cooldown  # Reset cooldown
	else:
		is_boosting = false
		
		# Recharge nitro after cooldown
		if nitro_cooldown_timer > 0:
			nitro_cooldown_timer -= delta
		else:
			current_nitro += nitro_recharge_rate * delta
			current_nitro = min(max_nitro, current_nitro)  # Clamp to max
	
	# Engine: Super responsive on light mass
	var engine_multiplier = nitro_boost_multiplier if is_boosting else 1.0
	
	if handbrake:
		engine_force = 0.0
		brake = handbrake_force
	else:
		engine_force = throttle * max_engine_force * engine_multiplier
		brake = 0.0 if throttle != 0 else max_brake_force

	# Steering: Quick & wide like toy
	var target_steer = steer_input * max_steer_angle
	steering = lerp(steering, target_steer, steer_speed * delta)

	# === ENGINE SOUND ===
	# Get average rear wheel RPM (realistic engine RPM)
	var rpm_left = abs($wheel_RL_COL.get_rpm())
	var rpm_right = abs($wheel_RR_COL.get_rpm())
	var avg_rpm = (rpm_left + rpm_right) / 2.0
	
	# Throttle-based pitch (0-1 normalized)
	var throttle_factor = abs(throttle)
	var rpm_factor = clamp(avg_rpm / 50.0, 0.0, 1.0)  # 50 RPM = max pitch
	
	# Combine throttle input + wheel RPM
	var pitch_target = idle_pitch + (max_pitch - idle_pitch) * max(throttle_factor, rpm_factor)
	
	# Boost sound (higher pitch when boosting)
	if is_boosting:
		pitch_target *= 1.2  # 20% higher pitch
	
	# Smooth pitch transition
	current_pitch = lerp(current_pitch, pitch_target, pitch_smoothing * delta)
	engine_sound.pitch_scale = current_pitch
	
	# Play horn on 'H' key
	if Input.is_action_just_pressed("Horn"):
		horn_sound.play()
