extends Node3D

# This script should be attached to the Environment scene root
# to initialize the timer when the level starts

func _ready():
	# Wait a frame to ensure GameManager is ready
	await get_tree().process_frame
	
	if GameManager:
		# Start the 5-minute countdown timer
		var timer_duration = 300  # 300 seconds = 5 minutes
		
		print("==========================================")
		print("LEVEL INITIALIZER - Starting timer")
		print("Timer duration set to: ", timer_duration, " seconds")
		print("This should be 300 for 5 minutes")
		print("==========================================")
		
		GameManager.start_timer(timer_duration)
		
		# Wait a moment and check what the timer actually is
		await get_tree().create_timer(0.5).timeout
		print("Timer display shows: ", GameManager.get_time_display())
		print("Time remaining: ", GameManager.time_remaining, " seconds")
		print("==========================================")
