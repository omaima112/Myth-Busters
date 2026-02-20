extends Node3D

func _ready():
	var orb_count: int = 0
	for child in get_children():
		if child.has_method("_on_car_entered"):
			orb_count += 1

	GameManager.initialize_orbs(orb_count)

	# No hardcoded number — uses GameManager.time_limit set by difficulty in menu
	GameManager.start_timer()

	if GameManager:
		GameManager.game_won.connect(func(_s): visible = false)
		GameManager.game_lost.connect(func(): visible = false)
		if GameManager.has_signal("game_busted"):
			GameManager.game_busted.connect(func(): visible = false)
		if GameManager.has_signal("police_chase_started"):
			GameManager.police_chase_started.connect(func(): visible = false)
		if GameManager.has_signal("police_chase_ended"):
			GameManager.police_chase_ended.connect(func(): visible = true)
