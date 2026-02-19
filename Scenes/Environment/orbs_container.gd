extends Node3D

func _ready():
	var orb_count: int = 0
	for child in get_children():
		if child.has_method("_on_car_entered"):
			orb_count += 1
	
	GameManager.initialize_orbs(orb_count)
	print("Total orbs in scene: ", orb_count)
	
	# START THE TIMER HERE - 300 SECONDS = 5 MINUTES
	print("==========================================")
	print("🕐 STARTING 5 MINUTE TIMER (300 seconds)")
	print("==========================================")
	GameManager.start_timer(300)
	
	# Hide orbs container on game end and police chase
	if GameManager:
		GameManager.game_won.connect(func(_s): visible = false)
		GameManager.game_lost.connect(func(): visible = false)
		if GameManager.has_signal("game_busted"):
			GameManager.game_busted.connect(func(): visible = false)
		if GameManager.has_signal("police_chase_started"):
			GameManager.police_chase_started.connect(func(): visible = false)
		if GameManager.has_signal("police_chase_ended"):
			GameManager.police_chase_ended.connect(func(): visible = true)
	
	# Verify it started
	await get_tree().create_timer(0.5).timeout
	print("⏱ Timer display: ", GameManager.get_time_display())
	print("⏱ Time remaining: ", GameManager.time_remaining, " seconds")
	print("==========================================")
