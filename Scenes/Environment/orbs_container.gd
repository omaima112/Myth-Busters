extends Node3D

func _ready():
	var orb_count: int = 0
	for child in get_children():
		if child.has_method("_on_car_entered"):
			orb_count += 1
	
	GameManager.initialize_orbs(orb_count)
	print("Total orbs in scene: ", orb_count)
