extends VehicleBody3D

@export var can_drive := true

# Toy Car Tuning (adjust in Inspector!)
@export var max_engine_force := 1200.0     # High relative to low mass = snappy!
@export var max_brake_force := 20.0        # Light braking for drifts
@export var handbrake_force := 40.0        # Strong skid for fun
@export var max_steer_angle := 0.7         # Wide turns
@export var steer_speed := 8.0             # Instant response

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

func _ready():
	# Auto-tune all wheels (toy car feel)
	initial_position = global_position
	initial_rotation = rotation
	
	for wheel in get_children():
		if wheel is VehicleWheel3D:
			# Grip & suspension (all wheels)
			wheel.wheel_friction_slip = wheel_friction_slip
			wheel.suspension_travel = suspension_travel
			wheel.suspension_stiffness = suspension_stiffness
			wheel.damping_compression = damping_compression
			wheel.damping_relaxation = damping_relaxation
			
			# Front wheels only: steering
			if wheel.position.z > 0:  # Assuming Z > 0 = front
				wheel.use_as_steering = true
			
			# Rear wheels only: drive
			if wheel.position.z < 0:  # Z < 0 = rear
				wheel.use_as_traction = true

func _physics_process(delta):
	
	# Reset on 'R' key
	if Input.is_action_just_pressed("Reset"):  # Default 'R' key
		reset_vehicle()
		
	var throttle = Input.get_action_strength("Gas") - Input.get_action_strength("Brake")
	var steer_input = Input.get_action_strength("Left") - Input.get_action_strength("Right")
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
	var throttle_factor = Input.get_action_strength("Gas")/2 if (Input.get_action_strength("Gas") - Input.get_action_strength("Brake")) > 0.5 else Input.get_action_strength("Brake")/4
	
	# Boost pitch higher when nitro active
	var pitch_max = max_pitch * 1.3 if is_boosting else max_pitch
	var target_pitch = lerp(idle_pitch, pitch_max, throttle_factor)
	
	# Smooth pitch lerp
	current_pitch = lerp(current_pitch, target_pitch, pitch_smoothing * delta)
	
	# Apply to sound
	engine_sound.pitch_scale = current_pitch
	
	# Volume swell with throttle (quieter idle)
	engine_sound.volume_db = lerp(-15.0, 0.0, throttle_factor)
	
	# === HORN ===
	if Input.is_action_pressed("Horn"):  # Press H
		if not horn_sound.playing:   # Prevents spam/overlapping
			horn_sound.play()

	if not Input.is_action_pressed("Horn") and horn_sound.playing:
		horn_sound.stop()

	# Debug
	print("Nitro: ", current_nitro, " | Boosting: ", is_boosting)


func _on_engine_off():
	engine_sound.pitch_scale = idle_pitch
	engine_sound.volume_db = -30.0  # Quiet idle

func reset_vehicle():
	global_position = initial_position
	rotation = initial_rotation
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	engine_force = 0.0
	brake = max_brake_force * 2
	steering = 0.0
	current_nitro = max_nitro  # Refill nitro on reset
	is_boosting = false

# Optional: Get nitro percentage for UI display
func get_nitro_percentage():
	return (current_nitro / max_nitro) * 100.0
