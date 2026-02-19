extends CharacterBody3D

@onready var agent = $NavigationAgent3D
@onready var siren = $AudioStreamPlayer3D

var SPEED = 10
var MAX_SPEED = 15
var ACCELERATION = 15
var DECELERATION = 20
var TURN_SPEED = 5.0
var DETECTION_RANGE = 30.0
var WANDER_RANGE = 25.0
var WANDER_TIMER = 3.0
var LIGHT_BLINK_SPEED = 0.3

var player_position = Vector3.ZERO
var is_chasing = false
var was_chasing = false   # tracks previous frame state for transitions
var current_speed = 0.0
var wander_time = 0.0
var wander_target = Vector3.ZERO
var light_blink_time = 0.0
var red_light = null
var blue_light = null

var jeep: Node = null
var jeep_in_zone: bool = false       # tracks whether jeep is currently in range
const BUST_RADIUS: float = 5.0       # 5 metre trigger zone


func _ready():
	agent.path_desired_distance = 0.5
	agent.target_desired_distance = 0.5
	pick_wander_target()
	setup_lights()
	setup_siren()

	collision_layer = 2
	collision_mask = 1

	await get_tree().process_frame
	jeep = get_tree().root.find_child("Jeep", true, false)
	print("🚔 Police ready | Jeep found: ", jeep != null)


func setup_lights():
	red_light = OmniLight3D.new()
	red_light.name = "RedLight"
	red_light.light_color = Color.RED
	red_light.omni_range = 8.0
	red_light.position = Vector3(-0.5, 2, 0)
	add_child(red_light)

	blue_light = OmniLight3D.new()
	blue_light.name = "BlueLight"
	blue_light.light_color = Color.CYAN
	blue_light.omni_range = 8.0
	blue_light.position = Vector3(0.5, 2, 0)
	add_child(blue_light)


func setup_siren():
	siren.bus = "Master"


func update_lights():
	if red_light == null or blue_light == null:
		return
	if is_chasing:
		light_blink_time += get_physics_process_delta_time()
		var blink_cycle = fmod(light_blink_time, LIGHT_BLINK_SPEED * 2)
		if blink_cycle < LIGHT_BLINK_SPEED:
			red_light.visible = true
			blue_light.visible = false
		else:
			red_light.visible = false
			blue_light.visible = true
	else:
		red_light.visible = false
		blue_light.visible = false


func update_siren():
	if is_chasing:
		if not siren.playing:
			siren.play()
	else:
		siren.stop()


func pick_wander_target():
	var random_offset = Vector3(
		randf_range(-WANDER_RANGE, WANDER_RANGE),
		0,
		randf_range(-WANDER_RANGE, WANDER_RANGE)
	)
	wander_target = global_transform.origin + random_offset
	wander_time = 0.0


func _physics_process(delta):
	var distance_to_player = global_transform.origin.distance_to(player_position)

	if distance_to_player <= DETECTION_RANGE:
		is_chasing = true
	else:
		is_chasing = false

	# === BARREL VISIBILITY — hide when chase starts, show when chase ends ===
	if is_chasing and not was_chasing:
		_set_barrels_visible(false)
		if GameManager and GameManager.has_signal("police_chase_started"):
			GameManager.police_chase_started.emit()
	elif not is_chasing and was_chasing:
		_set_barrels_visible(true)
		if GameManager and GameManager.has_signal("police_chase_ended"):
			GameManager.police_chase_ended.emit()
	was_chasing = is_chasing

	# === BUST ZONE — enter/leave detection, repeatable ===
	if jeep != null:
		var dist_to_jeep = global_transform.origin.distance_to(jeep.global_transform.origin)

		if dist_to_jeep <= BUST_RADIUS and not jeep_in_zone:
			# Jeep just entered the zone
			jeep_in_zone = true
			print("🚨 Jeep entered bust zone")
			if GameManager and GameManager.has_signal("player_in_bust_zone"):
				GameManager.player_in_bust_zone.emit()

		elif dist_to_jeep > BUST_RADIUS and jeep_in_zone:
			# Jeep just left the zone
			jeep_in_zone = false
			print("✅ Jeep left bust zone")
			if GameManager and GameManager.has_signal("player_left_bust_zone"):
				GameManager.player_left_bust_zone.emit()

	# === CHASE / WANDER MOVEMENT ===
	if is_chasing:
		if not agent.is_target_reached():
			var current_location = global_transform.origin
			var next_location = agent.get_next_path_position()
			var direction_to_target = (next_location - current_location).normalized()

			if direction_to_target.length() > 0:
				var target_rotation = atan2(direction_to_target.x, direction_to_target.z)
				var current_rotation = global_transform.basis.get_euler().y
				var rotation_difference = angle_difference(current_rotation, target_rotation)
				var rotation_step = clamp(rotation_difference, -TURN_SPEED * delta, TURN_SPEED * delta)
				rotate_y(rotation_step)

			current_speed = move_toward(current_speed, MAX_SPEED, ACCELERATION * delta)
		else:
			current_speed = move_toward(current_speed, 0, DECELERATION * delta)
	else:
		wander_time += delta
		if wander_time >= WANDER_TIMER:
			pick_wander_target()

		if not agent.is_target_reached():
			var current_location = global_transform.origin
			var next_location = agent.get_next_path_position()
			var direction_to_target = (next_location - current_location).normalized()

			if direction_to_target.length() > 0:
				var target_rotation = atan2(direction_to_target.x, direction_to_target.z)
				var current_rotation = global_transform.basis.get_euler().y
				var rotation_difference = angle_difference(current_rotation, target_rotation)
				var rotation_step = clamp(rotation_difference, -TURN_SPEED * delta, TURN_SPEED * delta)
				rotate_y(rotation_step)

			current_speed = move_toward(current_speed, SPEED * 0.6, ACCELERATION * delta)
		else:
			current_speed = move_toward(current_speed, 0, DECELERATION * delta)
			pick_wander_target()

	update_lights()
	update_siren()

	var forward_direction = global_transform.basis.z
	velocity = forward_direction * current_speed
	move_and_slide()



func _set_barrels_visible(active: bool) -> void:
	var barrels = get_tree().get_nodes_in_group("barrels")
	for barrel in barrels:
		if barrel.has_method("set_active"):
			barrel.set_active(active)
		else:
			barrel.visible = active
	print("🛢️ Barrels active: ", active, " (", barrels.size(), " barrels)")

func update_target_location(target_location):
	player_position = target_location
	if is_chasing:
		agent.target_position = target_location
	else:
		if wander_target != Vector3.ZERO:
			agent.target_position = wander_target
