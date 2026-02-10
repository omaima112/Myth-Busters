extends Control

@onready var start_button = $MainContainer/LeftPanel/StartButton
@onready var quit_button = $MainContainer/LeftPanel/QuitButton

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Menu loaded successfully!")
	
	# Connect buttons manually as backup
	if start_button and not start_button.is_connected("pressed", _on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
		print("Start button connected")
	
	if quit_button and not quit_button.is_connected("pressed", _on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)
		print("Quit button connected")

# Called when Start button is pressed
func _on_start_button_pressed():
	print("Start button pressed! Loading splash screen...")
	
	# Try to load the loading screen first
	var loading_screen_paths = [
		"res://Scenes/LoadingScreen.tscn",
		"res://LoadingScreen.tscn"
	]
	
	for path in loading_screen_paths:
		if ResourceLoader.exists(path):
			print("Found loading screen at: ", path)
			var error = get_tree().change_scene_to_file(path)
			if error != OK:
				print("Error loading loading screen: ", error)
			else:
				return  # Successfully loaded loading screen
	
	# If loading screen not found, try to load main scene directly
	print("Loading screen not found, loading main scene directly...")
	var main_scene_paths = [
		"res://Scenes/main.tscn",
		"res://main.tscn",
		"res://scenes/main.tscn"
	]
	
	for path in main_scene_paths:
		if ResourceLoader.exists(path):
			print("Found main scene at: ", path)
			var error = get_tree().change_scene_to_file(path)
			if error != OK:
				print("Error loading scene: ", error)
			return
	
	print("ERROR: Could not find main.tscn in any expected location!")
	print("Please update the paths in menu_enhanced.gd")

# Called when Quit button is pressed
func _on_quit_button_pressed():
	print("Quit button pressed! Exiting game...")
	get_tree().quit()

# Optional: Add keyboard controls
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed()
	elif event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
