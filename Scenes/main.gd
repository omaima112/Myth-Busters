extends Node3D

# The Player is inside the Jeep scene
@onready var player = $Jeep

func _physics_process(delta):
	if player:
		get_tree().call_group("enemies", "update_target_location", player.global_transform.origin)
