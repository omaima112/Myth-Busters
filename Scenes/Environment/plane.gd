extends Node3D

@export var plane: Node3D

@export var repeat_delay   : float = 2.0
@export var approach_speed : float = 18.0
@export var runway_speed   : float = 10.0
@export var takeoff_speed  : float = 15.0  # starting speed, accelerates from here

# ── Positions ──
const POS_SPAWN   = Vector3(-70.0, 20.751,  138.849)
const POS_LAND    = Vector3(-70.0,  1.135,   87.314)
const POS_RUNWAY  = Vector3(-70.0,  1.135,   20.387)
const POS_GONE    = Vector3(-70.0, 24.232,  -42.878)

# ── Rotations ──
const ROT_APPROACH = Vector3(84.3,  0.0, -180.0)
const ROT_GROUND   = Vector3(90.0,  0.0, -180.0)
const ROT_TAKEOFF  = Vector3(100.0, 0.0, -180.0)

enum State { IDLE, APPROACH, TAXI, TAKEOFF, DONE }
var _state       : State = State.IDLE
var _wait_timer  : float = 0.0
var _cur_speed   : float = 0.0


func _ready() -> void:
	plane.visible = false
	_reset()


func _reset() -> void:
	_state      = State.IDLE
	_wait_timer = repeat_delay
	plane.visible          = false
	plane.position         = POS_SPAWN
	plane.rotation_degrees = ROT_APPROACH


func _process(delta: float) -> void:
	match _state:

		State.IDLE:
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				plane.visible = true
				_cur_speed    = approach_speed
				_state        = State.APPROACH

		State.APPROACH:
			_move_toward(POS_LAND, ROT_GROUND, approach_speed, delta)
			if plane.position.distance_to(POS_LAND) < 0.3:
				plane.position = POS_LAND
				_cur_speed     = runway_speed
				_state         = State.TAXI

		State.TAXI:
			# Phase A — roll forward on runway at steady speed
			if plane.position.z > POS_RUNWAY.z:
				var dir = (POS_RUNWAY - plane.position).normalized()
				plane.position += dir * runway_speed * delta
				plane.rotation_degrees = plane.rotation_degrees.lerp(ROT_GROUND, delta * 3.0)
			else:
				# Phase B — past runway end, accelerate and pitch nose up instantly
				_cur_speed = lerp(_cur_speed, takeoff_speed * 2.5, delta * 1.2)
				var dir    = (POS_GONE - plane.position).normalized()
				plane.position         += dir * _cur_speed * delta
				plane.rotation_degrees  = plane.rotation_degrees.lerp(ROT_TAKEOFF, delta * 2.5)

				if plane.position.distance_to(POS_GONE) < 1.5:
					_state = State.DONE

		State.DONE:
			_reset()


# Moves plane toward target pos and smoothly rotates to target rot
func _move_toward(target_pos: Vector3, target_rot: Vector3, speed: float, delta: float) -> void:
	var dir = (target_pos - plane.position).normalized()
	plane.position         += dir * speed * delta
	plane.rotation_degrees  = plane.rotation_degrees.lerp(target_rot, delta * 3.0)
