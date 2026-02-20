extends Area3D

# Zone settings (customize in Inspector)
@export var zone_name := "Radiation Zone"
@export var max_radiation := 100.0
@export var radiation_speed := 25.0

# Reference to UI (will auto-find sibling)
@onready var radiation_ui: CanvasLayer = get_node("../RadiationUI")

var player_in_zone := false
var current_radiation := 0.0

func _ready():
	# Monitor ALL collision layers to catch the player
	collision_mask = 4294967295  # All bits set to 1
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if player_in_zone and radiation_ui and radiation_ui.has_method("set_radiation"):
		current_radiation += radiation_speed * delta
		current_radiation = clamp(current_radiation, 0.0, max_radiation)
		radiation_ui.set_radiation(current_radiation)

func _on_body_entered(body):
	if is_player(body):
		player_in_zone = true
		current_radiation = 0.0

func _on_body_exited(body):
	if is_player(body):
		player_in_zone = false
		current_radiation = 0.0
		if radiation_ui and radiation_ui.has_method("set_radiation"):
			radiation_ui.set_radiation(0.0)

func is_player(body) -> bool:
	# Exclude police/enemies — they are CharacterBody3D but should never trigger radiation
	if body.is_in_group("enemies"):
		return false
	# Detects VehicleBody3D, CharacterBody3D, or anything in "player" group
	return body is VehicleBody3D \
		or body is CharacterBody3D \
		or body.is_in_group("player")
