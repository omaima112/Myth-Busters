extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure the buttons are connected (already done in scene)
	# You can add any initialization here, like playing background music
	pass

# Called when Start button is pressed
func _on_start_button_pressed():
	# Change to the main game scene
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

# Called when Quit button is pressed
func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()

# Optional: Add keyboard controls
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed()
	elif event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
