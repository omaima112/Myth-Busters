extends Control

func _ready():
	print("MENU LOADED - Script is working!")
	# Manually connect buttons in case scene connections fail
	var start_btn = get_node_or_null("MainContainer/LeftPanel/StartButton")
	var quit_btn = get_node_or_null("MainContainer/LeftPanel/QuitButton")

	
	if start_btn:
		if not start_btn.pressed.is_connected(_on_start_button_pressed):
			start_btn.pressed.connect(_on_start_button_pressed)

	if quit_btn:
		if not quit_btn.pressed.is_connected(_on_quit_button_pressed):
			quit_btn.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	print("START GAME clicked")
	get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")

	print("MULTIPLAYER clicked!")
	var path = "res://scenes/multiplayer.tscn"
	if ResourceLoader.exists(path):
		print("Scene found, loading: " + path)
		get_tree().change_scene_to_file(path)
	else:
		print("ERROR: Scene not found at: " + path)

func _on_quit_button_pressed():
	print("QUIT clicked")
	get_tree().quit()
