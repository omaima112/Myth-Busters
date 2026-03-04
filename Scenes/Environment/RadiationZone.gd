extends Area3D

@export var zone_name       := "Radiation Zone"
@export var max_radiation   := 100.0
@export var radiation_speed := 25.0

# Searches the entire scene tree — works no matter how deep this node is
@onready var radiation_ui: CanvasLayer = get_tree().get_root().find_child("RadiationUI", true, false)

var player_in_zone       := false
var current_radiation    := 0.0


func _ready():
	collision_mask = 4294967295
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if not radiation_ui:
		push_error("RadiationZone: Could not find RadiationUI anywhere in the scene tree!")


func _process(delta):
	if player_in_zone and radiation_ui and radiation_ui.has_method("set_radiation"):
		current_radiation += radiation_speed * delta
		current_radiation  = clamp(current_radiation, 0.0, max_radiation)
		radiation_ui.set_radiation(current_radiation)


func _on_body_entered(body):
	if is_player(body):
		player_in_zone    = true
		current_radiation = 0.0


func _on_body_exited(body):
	if is_player(body):
		player_in_zone    = false
		current_radiation = 0.0
		if radiation_ui and radiation_ui.has_method("set_radiation"):
			radiation_ui.set_radiation(0.0)


func is_player(body) -> bool:
	if body.is_in_group("enemies"):
		return false
	return body is VehicleBody3D \
		or body is CharacterBody3D \
		or body.is_in_group("player")
