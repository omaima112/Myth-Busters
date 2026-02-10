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
	# FIX: Monitor ALL collision layers to catch the player
	collision_mask = 4294967295  # Monitor all layers (all bits set to 1)
	
	print("\n========== RADIATION ZONE READY ==========")
	print("Zone name:", zone_name)
	print("Max radiation:", max_radiation)
	print("Radiation speed:", radiation_speed)
	print("Monitoring layer:", collision_mask)
	
	# Check if we found the UI
	if radiation_ui:
		print("✅ RadiationUI found!")
	else:
		print("❌ WARNING: RadiationUI not found!")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("==========================================\n")

func _process(delta):
	if player_in_zone and radiation_ui and radiation_ui.has_method("set_radiation"):
		# Increase radiation while player is in zone
		current_radiation += radiation_speed * delta
		current_radiation = clamp(current_radiation, 0.0, max_radiation)
		radiation_ui.set_radiation(current_radiation)
	elif player_in_zone and radiation_ui:
		print("❌ ERROR: RadiationUI doesn't have set_radiation() method!")
		print("   Make sure RadiationUI.gd script is attached to the RadiationUI node!")

func _on_body_entered(body):
	print("\n➡ Body entered:", body.name, "|", body.get_class())
	
	if is_player(body):
		player_in_zone = true
		current_radiation = 0.0
		print("🚗 PLAYER ENTERED RADIATION ZONE:", zone_name)

func _on_body_exited(body):
	print("\n⬅ Body exited:", body.name)
	
	if is_player(body):
		player_in_zone = false
		current_radiation = 0.0
		if radiation_ui and radiation_ui.has_method("set_radiation"):
			radiation_ui.set_radiation(0.0)
		print("🚪 PLAYER EXITED RADIATION ZONE:", zone_name)

func is_player(body) -> bool:
	# Detects VehicleBody3D, CharacterBody3D, or anything in "player" group
	return body is VehicleBody3D \
		or body is CharacterBody3D \
		or body.is_in_group("player")
