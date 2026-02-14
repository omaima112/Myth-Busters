extends Node3D

# This script should be attached to the Environment scene root
# to initialize the timer when the level starts

func _ready():
	# Wait a frame to ensure GameManager is ready
	await get_tree().process_frame
	
	if GameManager:
		# Start the 7-minute countdown timer
		var timer_duration = 420  # 420 seconds = 7 minutes
		
		print("==========================================")
		print("LEVEL INITIALIZER - Starting timer")
		print("Timer duration set to: ", timer_duration, " seconds")
		print("==========================================")
		
		GameManager.start_timer(timer_duration)
		
		# Wait a moment and check what the timer actually is
		await get_tree().create_timer(0.5).timeout
		print("Timer display shows: ", GameManager.get_time_display())
		print("Time remaining: ", GameManager.time_remaining, " seconds")
		print("==========================================")
	
	print("✅ K key skip is ready - Press K to jump to Level 2")

# 🔑 SECRET SKIP TO LEVEL 2 - Press K key
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_K:
			get_tree().root.set_input_as_handled()
			print("🔑 K KEY PRESSED - Loading Level 2!")
			skip_to_level_2()

func skip_to_level_2():
	"""Load loading screen which then loads level 2"""
	print("🔄 Changing to loading screen...")
	get_tree().change_scene_to_file("res://Scenes/Levels/LoadingScreen_Level2_Final.tscn")
