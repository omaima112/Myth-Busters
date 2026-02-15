extends Control

@onready var timer_label = $TimerLabel

func _ready():
	print("🎯 Timer HUD initialized for Level 2")
	
	# Check if GameManager exists
	if not GameManager:
		print("❌ ERROR: GameManager not found!")
		return
	
	print("✅ GameManager found")
	
	# Disconnect first to avoid duplicate connections on reload
	if GameManager.timer_updated.is_connected(_on_timer_updated):
		print("📌 Disconnecting previous timer_updated signal")
		GameManager.timer_updated.disconnect(_on_timer_updated)
	
	# Connect to timer updates
	print("📌 Connecting to timer_updated signal...")
	GameManager.timer_updated.connect(_on_timer_updated)
	
	# ✅ Check if GameManager has the methods we need
	if not GameManager.has_method("set_time_remaining"):
		print("⚠️ WARNING: GameManager doesn't have set_time_remaining method")
		print("   Available methods: set_time, time_remaining, reset_timer, etc.")
	
	# ✅ Try to set timer to 5 minutes (300 seconds)
	if GameManager.has_method("set_time_remaining"):
		print("⏱️ Setting timer to 5 minutes (300 seconds)...")
		GameManager.set_time_remaining(300)
	elif GameManager.has_method("set_time"):
		print("⏱️ Using set_time() method...")
		GameManager.set_time(300)
	elif GameManager.has_method("reset_timer"):
		print("⏱️ Using reset_timer() method...")
		GameManager.reset_timer()
	
	# Display initial time
	var initial_time = GameManager.get_time_display()
	print("⏱️ Initial time: ", initial_time)
	timer_label.text = initial_time
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	
	# ✅ Start the timer
	if GameManager.has_method("start_timer"):
		print("🔔 Starting timer with start_timer()...")
		GameManager.start_timer()
	else:
		print("⚠️ WARNING: GameManager doesn't have start_timer method")
	
	print("✅ Timer HUD ready!")

func _on_timer_updated(time_remaining: int):
	"""Update the timer display when GameManager updates it"""
	if timer_label == null:
		return
	
	var minutes = time_remaining / 60
	var seconds = time_remaining % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	#print("⏱️ Timer updated: ", timer_label.text)  # Uncomment for debugging
	
	# Color feedback based on time remaining
	if time_remaining <= 30 and time_remaining > 0:
		# Under 30 seconds — red warning
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining <= 60:
		# Under 1 minute — orange caution
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		# Plenty of time — white (normal)
		timer_label.add_theme_color_override("font_color", Color.WHITE)
