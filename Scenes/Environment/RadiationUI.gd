extends CanvasLayer

# UI elements
var radiation_label: Label
var radiation_bar: ProgressBar

# Current radiation level (0-100)
var current_radiation := 0.0

func _ready():
	print("========== RADIATION UI STARTING ==========")
	
	# Get references to child nodes (through Control node)
	radiation_label = $Control/VBoxContainer/Label
	radiation_bar = $Control/VBoxContainer/ProgressBar
	
	if radiation_label:
		print("✅ Label found!")
	else:
		print("❌ ERROR: Label NOT found!")
	
	if radiation_bar:
		print("✅ ProgressBar found!")
		radiation_bar.min_value = 0
		radiation_bar.max_value = 30
		radiation_bar.value = 0
		radiation_bar.show_percentage = false
		print("   Min:", radiation_bar.min_value, "Max:", radiation_bar.max_value)
	else:
		print("❌ ERROR: ProgressBar NOT found!")
	
	# Make sure UI is visible
	visible = true
	
	# Initial display
	set_radiation(0.0)
	
	print("==========================================")

func _process(_delta):
	# Update display every frame
	if radiation_label:
		radiation_label.text = "☢ RADIATION LEVEL: %.1f μSv/h" % current_radiation
		
		# Change color based on level
		if current_radiation < 1:
			radiation_label.modulate = Color(0.2, 1.0, 0.2)  # Green
		elif current_radiation < 5:
			radiation_label.modulate = Color(1.0, 1.0, 0.0)  # Yellow
		elif current_radiation < 10:
			radiation_label.modulate = Color(1.0, 0.5, 0.0)  # Orange
		else:
			radiation_label.modulate = Color(1.0, 0.0, 0.0)  # Red
	
	if radiation_bar:
		radiation_bar.value = current_radiation
		
		# Change bar color
		if current_radiation < 1:
			radiation_bar.modulate = Color(0.2, 1.0, 0.2)
		elif current_radiation < 5:
			radiation_bar.modulate = Color(1.0, 1.0, 0.0)
		elif current_radiation < 10:
			radiation_bar.modulate = Color(1.0, 0.5, 0.0)
		else:
			radiation_bar.modulate = Color(1.0, 0.0, 0.0)

func set_radiation(value: float):
	current_radiation = clamp(value, 0.0, 30)
	print("🎯 RADIATION SET TO:", current_radiation)
	
	if radiation_bar:
		radiation_bar.value = current_radiation
